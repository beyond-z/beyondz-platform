class Feedback < ActionMailer::Base
  default from: 'no-reply@beyondz.org'

  def feedback(from, message)
    @from = from
    @message = message
    mail(to: 'tech@beyondz.org', subject: 'Site Feedback')
  end
end
