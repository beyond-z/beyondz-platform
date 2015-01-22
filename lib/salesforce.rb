module BeyondZ
  class Salesforce
    public

    def get_client
      client = Databasedotcom::Client.new
      client.authenticate(
        :username => Rails.application.secrets.salesforce_username,
        :password => "#{Rails.application.secrets.salesforce_password}#{Rails.application.secrets.salesforce_security_token}"
      )

      client
    end

    def get_welcome_email
      client = get_client
      client.materialize('EmailTemplate')

      template = EmailTemplate.find_by_DeveloperName('New_Signup_Welcome_and_Confirm_Email')
      #New_Signup_Welcome_and_Confirm_Email_Html

      template.Body
    end
  end
end
