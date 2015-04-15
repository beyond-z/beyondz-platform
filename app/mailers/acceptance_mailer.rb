require 'digest/sha2'
class AcceptanceMailer < ActionMailer::Base
  default from: '"Beyond Z" <no-reply@beyondz.org>'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default "Message-ID" => ->(v){"<#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@beyondz.org>"}

  def request_availability_confirmation(user)
    @user = user

    @confirm_link = user_confirm_url

    mail(to: user.email, subject: 'Please confirm your availability')
  end
end
