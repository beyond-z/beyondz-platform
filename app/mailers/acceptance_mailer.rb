require 'digest/sha2'
class AcceptanceMailer < ActionMailer::Base
  default 'from' => '"Braven" <' + Rails.application.secrets.mailer_from_email + '>'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@beyondz.org>" }

  def request_availability_confirmation(user)
    @user = user

    @confirm_link = user_confirm_url

    mail(to: user.email, subject: 'Please confirm your availability')
  end
end
