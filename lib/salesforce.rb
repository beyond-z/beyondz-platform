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

    def run_report(report_id)
      client = get_client
      info = client.http_get("/services/data/v29.0/analytics/reports/#{report_id}?includeDetails=true")
      info = JSON.parse(info.body)

      # App:
      #  225953769019-dknslqms22l6tmapmk48d83jndoos9t8.apps.googleusercontent.com 
      #  y2oLQ0F3dN83x2UrqLkMR8ew 
      # User:
      #  refresh_token: 1/qhB2G_ufJcVL2lOWuIB9hcskIYmlXJo8RU35Ba_rbmI

      client = Google::APIClient.new({ :application_name => 'Braven', :application_version => '1.0.0' })
      auth = client.authorization
      auth.client_id = '225953769019-dknslqms22l6tmapmk48d83jndoos9t8.apps.googleusercontent.com'
      auth.client_secret = 'y2oLQ0F3dN83x2UrqLkMR8ew'
      auth.refresh_token = '1/qhB2G_ufJcVL2lOWuIB9hcskIYmlXJo8RU35Ba_rbmI'

      auth.fetch_access_token!
      session = GoogleDrive.login_with_oauth(auth.access_token)

      sheet = session.spreadsheet_by_key('1o7xw027aHE_jdTSs58ByWTYuGVd2-9ml8lVHMJUL7Lo')

      ws = sheet.worksheets[5] # a new sheet at the end...

      row = 1
      col = 1

      info['reportMetadata']['detailColumns'].each do |column|
        ws[row, col] = column
        col += 1
      end

      col = 1
      row += 1

      info['groupingsDown']['groupings'].each do |grouping|
         ws[row, 1] = grouping['label']
         row += 1

         source_section = info['factMap']["#{grouping['key']}!T"]

         source_section['rows'].each do |source_row|
          col = 1
          source_row['dataCells'].each do |source_cell|
            ws[row, col] = source_cell['value']
            col += 1
          end
          row += 1
        end
      end

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
      get_email_cache('BZ_New_Signup_Welcome_and_Confirm_Email_Html.html')
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
