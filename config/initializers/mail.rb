if Rails.env.production?

  ActionMailer::Base.smtp_settings = {
    :address => Rails.application.secrets.smtp_server,
    :port => 587,
    :domain => Rails.application.secrets.smtp_domain,
    :user_name => Rails.application.secrets.smtp_username,
    :password => Rails.application.secrets.smtp_password,
    :authentication => :login # plain, login, or cram_md5i
    # gmail smtp server relay settings.  not for use on production.
    #:authentication => :plain,
    #:enable_starttls_auto => true
 }

  # Even in a production environment, we want to check the env var for
  # our staging setup for testing or other purposes, so real users don't
  # receive test emails.
  unless Rails.application.secrets.smtp_override_recipient.nil? || Rails.application.secrets.smtp_override_recipient.empty?
    class OverrideRecipientInterceptor
      def delivering_email(message)
        message.to = [Rails.application.secrets.smtp_override_recipient]
        message.cc = nil
        message.bcc = nil
      end
    end

    ActionMailer::Base.register_interceptor(OverrideRecipientInterceptor.new)
  end


else

  ActionMailer::Base.smtp_settings = {
    :address => Rails.application.secrets.smtp_server,
    :port => 587,
    :domain => Rails.application.secrets.smtp_domain,
    :user_name => Rails.application.secrets.smtp_username,
    :password => Rails.application.secrets.smtp_password,
    :authentication => :login # plain, login, or cram_md5i
    # gmail smtp server relay settings.  not for use on production.
    #:authentication => :plain,
    #:enable_starttls_auto => true
  }

  # In a non-production environment, send all outgoing emails to a single email that can be used for
  # testing or other purposes, so real users don't receive test emails.
  class OverrideRecipientInterceptor
    def delivering_email(message)
      message.to = [Rails.application.secrets.smtp_override_recipient]
      message.cc = nil
      message.bcc = nil
    end
  end

  ActionMailer::Base.register_interceptor(OverrideRecipientInterceptor.new)

end
