if Rails.env.production?

  ActionMailer::Base.smtp_settings = {
    :address => ENV['SMTP_SERVER'],
    :port => 587,
    :domain => "beyondz.org",
    :authentication => :plain,
    :user_name => ENV['SMTP_USERNAME'],
    :password => ENV["SMTP_PASSWORD"],
    :enable_starttls_auto => true
  }

else

  ActionMailer::Base.smtp_settings = {
    :address => ENV['SMTP_SERVER'],
    :port => 587,
    :domain => "beyondz.com",
    :authentication => :plain,
    :user_name => ENV['SMTP_USERNAME'],
    :password => ENV['SMTP_PASSWORD'],
    :enable_starttls_auto => true
  }

  # In a non-production environment, send all outgoing emails to a single email that can be used for
  # testing or other purposes, so real users don't receive test emails.
  class OverrideRecipientInterceptor
    def delivering_email(message)
      message.to = ENV['SMTP_OVERRIDE_RECIPIENT']
      message.cc = nil
      message.bcc = nil
    end
  end

  ActionMailer::Base.register_interceptor(OverrideRecipientInterceptor.new)

end
