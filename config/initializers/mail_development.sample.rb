if Rails.env.development?

  # ActionMailer::Base.smtp_settings = {
  #   :address => "smtp.gmail.com", # if you have a gmail account
  #   :port => 587,
  #   :domain => "beyondz.com",
  #   :authentication => :plain,
  #   :user_name => "your email",
  #   :password => "password",
  #   :enable_starttls_auto => true
  # }

  # class DevelopmentRecipientInterceptor
  #   def delivering_email(message)
  #     message.to = "your email"
  #     message.cc = nil
  #     message.bcc = nil
  #   end
  # end

  # ActionMailer::Base.register_interceptor(DevelopmentRecipientInterceptor.new)

end