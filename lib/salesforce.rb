# Namespacing for the salesforce modules, see:
# https://developer.salesforce.com/page/Accessing_Salesforce_Data_From_Ruby
module SFDC_Models
end

module BeyondZ
  class Salesforce
    public

    def get_client
      client = Databasedotcom::Client.new :host => Rails.application.secrets.salesforce_host
      client.sobject_module = SFDC_Models
      authenticate(client)

      client
    end

    def authenticate(client)
      client.authenticate(
        :username => Rails.application.secrets.salesforce_username,
        :password => "#{Rails.application.secrets.salesforce_password}#{Rails.application.secrets.salesforce_security_token}"
      )
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
  end
end
