require 'digest/sha2'
class ConfirmationFlow < ActionMailer::Base
  default 'from' => '"Braven" <' + Rails.application.secrets.mailer_from_email + '>'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@bebraven.org>" }

  def coach_confirmed(recipient, program_title, program_site, timeslot)
    @recipient = recipient
    @program_title = program_title
    @program_site = program_site
    @timeslot = timeslot

    sf = BeyondZ::Salesforce.new
    mail to: recipient.email, subject: sf.get_coach_confirmed_email_subject
  end

end
