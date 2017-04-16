# Namespacing for the salesforce modules, see:
# https://developer.salesforce.com/page/Accessing_Salesforce_Data_From_Ruby
module SFDC_Models
end

require "google/api_client"

# I'm monkeypatching the databasedotcom gem to fix a major bug
Databasedotcom::Client.class_eval do
  # This method is copy/pasted from the gem source with one
  # change: the const_defined is told not to search inherited
  # members. Without this change, we're stuck with heisenbugs
  # because Rails autoloads our models. If ours is used, it is
  # autoloaded and then Databasedotcom thinks it is the Salesforce
  # model because the share the name, and the const_defined will
  # look at inherited members... which includes the global Object
  # where the ActiveRecord models are found.
  #
  # The bug doesn't manifest itself if our class was not used in
  # that server session, making this a bit hard to test: you can't
  # go direct to it. You must first exercise a code path that instantiates
  # our object, then try the SF one.
  #
  # Easiest way to do that is in the console: create an object of our
  # class first, then try the SF class. Without this patch, it will
  # "succeed" by instantiating our class both times, leading to MethodMissing
  # errors. With this patch, it does the right thing.
  def materialize(classnames)
    classes = (classnames.is_a?(Array) ? classnames : [classnames]).collect do |clazz|
      original_classname = clazz
      clazz = original_classname[0,1].capitalize + original_classname[1..-1]
      unless module_namespace.const_defined?(clazz, false)
        new_class = module_namespace.const_set(clazz, Class.new(Databasedotcom::Sobject::Sobject))
        new_class.client = self
        new_class.materialize(original_classname)
        new_class
      else
        module_namespace.const_get(clazz)
      end
    end

    classes.length == 1 ? classes.first : classes
  end

end

module BeyondZ
  class Salesforce
    public

    def load_cached_campaign(campaign_id, client = nil)
      Rails.cache.fetch("salesforce/campaign/#{campaign_id}", expires_in: 12.hours) do
        client = get_client if client.nil?
        client.materialize('Campaign')
        SFDC_Models::Campaign.find(campaign_id)
      end
    end

    def get_client
      client = Databasedotcom::Client.new :host => Rails.application.secrets.salesforce_host
      client.sobject_module = SFDC_Models
      authenticate(client)

      # We need to update this too so the SFDC_Models don't try to use
      # an old client between server restarts - this will avoid the session
      # expired problem as we reauthorize and fix the global too.
      Databasedotcom::Sobject::Sobject.client = client

      client
    end

    def authenticate(client)
      client.authenticate(
        :username => Rails.application.secrets.salesforce_username,
        :password => "#{Rails.application.secrets.salesforce_password}#{Rails.application.secrets.salesforce_security_token}"
      )
    end

    # Returns the Salesforce ID of the contact if they exist or nil if not
    def exists_in_salesforce(email)
      client = get_client
      # Note: this doesn't work if there is a + in the email.  I can escape it and call the REST API like this in the workbench:
      # /services/data/v22.0/query?q=SELECT+Id+FROM+Contact+WHERE+Email+=+'brian%2Btestcalendlyvolunteer4@bebraven.org'
      # but from this gem, it doesn't work.  Would have to dig into the guts of what the gem is doing to fix.  It's already been an
      # hour, so I'm punting on getting that working.
      escaped_email = email.sub('\'', '\'\'') # This is a poor man's SQL escape so that an apostrophe doesn't break the SQL query.
      url_path = "/services/data/v#{client.version}/query?q=" \
        "SELECT Id FROM Contact WHERE Email = '#{escaped_email}'"
      salesforce_existing_record = client.http_get(url_path)
      sf_answer = JSON.parse(salesforce_existing_record.body)
      salesforce_existing_record = sf_answer['records']

      if salesforce_existing_record.empty?
        return nil
      else
        return salesforce_existing_record.first['Id']
      end
    end

    def run_report_and_email_update(report_id, file_key, worksheet_name, email_to_send_update_to)
      if email_to_send_update_to.nil?
        email_to_send_update_to = Rails.application.secrets.staff_email
      end

      begin
        run_report(report_id, file_key, worksheet_name)
        StaffNotifications.salesforce_report_ready(email_to_send_update_to, true, 'Success!').deliver
      rescue Exception => e
        StaffNotifications.salesforce_report_ready(email_to_send_update_to, false, e.to_s).deliver
      end
    end

    def run_report(report_id, file_key, worksheet_name)
      client = get_client
      info = client.http_get("/services/data/v29.0/analytics/reports/#{report_id}?includeDetails=true")
      info = JSON.parse(info.body)

      client = Google::APIClient.new({ :application_name => 'Braven', :application_version => '1.0.0' })
      auth = client.authorization
      auth.client_id = Rails.application.secrets.google_spreadsheet_client_id
      auth.client_secret = Rails.application.secrets.google_spreadsheet_client_secret
      auth.refresh_token = Rails.application.secrets.google_spreadsheet_refresh_token

      auth.fetch_access_token!
      session = GoogleDrive.login_with_oauth(auth.access_token)

      sheet = session.spreadsheet_by_key(file_key)

      ws = sheet.worksheet_by_title(worksheet_name)

      row = 1
      col = 1
      total_cols = 0
      total_rows = 0

      info['reportMetadata']['detailColumns'].each do |column|
        ws[row, col] = column
        col += 1
        total_cols += 1
      end

      col = 1
      row += 1
      total_rows += 1

      handle_section = lambda do |source_section|
        return if source_section.nil?
        source_section['rows'].each do |source_row|
          col = 1
          source_row['dataCells'].each do |source_cell|
            ws[row, col] = source_cell['label']
            col += 1
          end
          row += 1
          total_rows += 1

          # experiment: try saving partial data every 300 rows
          # to avoid "request entity too large" errors from google
          # on large reports
          if total_rows % 300 == 0
            ws.max_rows = total_rows
            ws.max_cols = total_cols

            ws.save
          end


        end
      end

      handle_section.call(info['factMap']["T!T"])

      info['groupingsDown']['groupings'].each do |grouping|
        ws[row, 1] = grouping['label']
        row += 1
        total_rows += 1

        handle_section.call(info['factMap']["#{grouping['key']}!T"])
      end

      # Truncate the rest of the sheet so it only has what we just updated
      # (will remove zombie rows from old updates with more data than this one)
      ws.max_rows = total_rows
      ws.max_cols = total_cols

      ws.save

    end

    def get_cached_value(key, max_age = 8.hours)
      cached = SalesforceCache.where(:key => key)
      if cached.empty? || cached.first.updated_at + max_age < DateTime.now
          return nil
      end

      cached.first.value
    end

    def set_cached_value(key, value)
      cached = SalesforceCache.where(:key => key)
      if cached.empty?
        SalesforceCache.create(:key => key, :value => value)
      else
        obj = cached.first
        obj.updated_at = DateTime.now
        obj.value = value
        obj.save!
      end

      value
    end

    def update_email_caches
      client = get_client
      client.materialize('EmailTemplate')

      template = SFDC_Models::EmailTemplate.find_by_DeveloperName('BZ_New_Signup_Welcome_and_Confirm_Email_Html')

      if template
        # We can also update the Subject on this request since we have it here anyway
        set_cached_value('BZ_New_Signup_Welcome_and_Confirm_Email_Subject', template.Subject)
        # ditto for the text version
        set_cached_value('BZ_New_Signup_Welcome_and_Confirm_Email_Html.text', template.Body)
        # And cache the HTML, of course
        set_cached_value('BZ_New_Signup_Welcome_and_Confirm_Email_Html.html', template.HtmlValue)
      end


      template = SFDC_Models::EmailTemplate.find_by_DeveloperName('BZ_Coach_Confirmed_Email_Html')

      if template
        # We can also update the Subject on this request since we have it here anyway
        set_cached_value('BZ_Coach_Confirmed_Email_Html_Subject', template.Subject)
        # ditto for the text version
        set_cached_value('BZ_Coach_Confirmed_Email_Html.text', template.Body)
        # And cache the HTML, of course
        set_cached_value('BZ_Coach_Confirmed_Email_Html.html', template.HtmlValue)
      end

      template = SFDC_Models::EmailTemplate.find_by_DeveloperName('BZ_Student_Confirmed_Email_Html')

      if template
        # We can also update the Subject on this request since we have it here anyway
        set_cached_value('BZ_Student_Confirmed_Email_Html_Subject', template.Subject)
        # ditto for the text version
        set_cached_value('BZ_Student_Confirmed_Email_Html.text', template.Body)
        # And cache the HTML, of course
        set_cached_value('BZ_Student_Confirmed_Email_Html.html', template.HtmlValue)
      end
    end

    def get_email_cache(cache_key)
      cache = get_cached_value(cache_key)
      if cache.nil?
        update_email_caches
        cache = get_cached_value(cache_key)
      end

      cache
    end

    def get_welcome_email_subject
      get_email_cache('BZ_New_Signup_Welcome_and_Confirm_Email_Subject')
    end

    def get_welcome_email_html
      get_email_cache('BZ_New_Signup_Welcome_and_Confirm_Email_Html.html').
        sub('<![CDATA[', '').
        sub(']]>', '')
    end 

    def get_welcome_email_text
      get_email_cache('BZ_New_Signup_Welcome_and_Confirm_Email_Html.text')
    end

    def get_coach_confirmed_email_subject
      get_email_cache('BZ_Coach_Confirmed_Email_Html_Subject')
    end

    def get_coach_confirmed_email_html
      get_email_cache('BZ_Coach_Confirmed_Email_Html.html')
    end 

    def get_coach_confirmed_email_text
      get_email_cache('BZ_Coach_Confirmed_Email_Html.text')
    end

    def get_student_confirmed_email_subject
      get_email_cache('BZ_Student_Confirmed_Email_Html_Subject')
    end

    def get_student_confirmed_email_html
      get_email_cache('BZ_Student_Confirmed_Email_Html.html')
    end 

    def get_student_confirmed_email_text
      get_email_cache('BZ_Student_Confirmed_Email_Html.text')
    end

  end
end
