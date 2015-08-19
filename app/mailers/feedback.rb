require 'digest/sha2'
class Feedback < ActionMailer::Base
  default 'from' => '"Braven" <' + Rails.application.secrets.mailer_from_email + '>'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@bebraven.org>" }

  def feedback(from, message)
    @from = from
    @message = message
    mail(to: 'tech@beyondz.org', subject: 'Site Feedback')
  end
end
