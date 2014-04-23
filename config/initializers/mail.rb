ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => "beyondz.org",
  :authentication => :plain,
  :user_name => ENV["GMAIL_USERNAME"],
  :password => ENV["GMAIL_PASSWORD"],
  :enable_starttls_auto => true
}
