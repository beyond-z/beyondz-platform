# Namespacing for the salesforce modules, see:
# https://developer.salesforce.com/page/Accessing_Salesforce_Data_From_Ruby
module SFDC_Models
end

module BeyondZ
  class Salesforce
    public

    def get_client
      client = Databasedotcom::Client.new
      client.sobject_module = 'SFDC_Models'
      client.authenticate(
        :username => Rails.application.secrets.salesforce_username,
        :password => "#{Rails.application.secrets.salesforce_password}#{Rails.application.secrets.salesforce_security_token}"
      )

      client
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
        obj.value = value
        obj.save!
      end

      value
    end

    def get_welcome_email_html
      cache_key = 'New_Signup_Welcome_and_Confirm_Email_Html.html'

      cache = get_cached_value(cache_key)
      if cache.nil?
        client = get_client
        client.materialize('EmailTemplate')

        template = SFDC_Models::EmailTemplate.find_by_DeveloperName('New_Signup_Welcome_and_Confirm_Email_Html')

        cache = set_cached_value(cache_key, template.HtmlValue)
      end

      cache
    end

    def get_welcome_email_text
      cache_key = 'New_Signup_Welcome_and_Confirm_Email_Html.text'

      cache = get_cached_value(cache_key)
      if cache.nil?
        client = get_client
        client.materialize('EmailTemplate')

        template = SFDC_Models::EmailTemplate.find_by_DeveloperName('New_Signup_Welcome_and_Confirm_Email_Html')

        cache = set_cached_value(cache_key, template.Body)
      end

      cache
    end
  end
end
