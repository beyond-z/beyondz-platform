require 'digest/sha2'
class ConfirmationFlow < ActionMailer::Base
  default 'from' => '"Braven" <' + Rails.application.secrets.mailer_from_email + '>'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@bebraven.org>" }

  def new_user(user)
    @user = user
    mail(to: user.email, subject: 'Braven Login Info')
  end

  def coach_confirmed(recipient, program_title, program_site, timeslot)
    @recipient = recipient
    @program_title = program_title
    @program_site = program_site
    @timeslot = timeslot

    sf = BeyondZ::Salesforce.new
    mail to: recipient.email, subject: sf.get_coach_confirmed_email_subject
      .gsub('{!Contact.FirstName}', @recipient.first_name)
      .gsub('{!Contact.LastName}', @recipient.last_name)
      .gsub('{!Program.Title}', @program_title)
      .gsub('{!Program.Site}', @program_site)
      .gsub('{!Timeslot}', @timeslot).html_safe
  end

  def student_confirmed(recipient, program_title, program_site, timeslot)
    @recipient = recipient
    @program_title = program_title
    @program_site = program_site
    @timeslot = timeslot

    sf = BeyondZ::Salesforce.new
    mail to: recipient.email, subject: sf.get_student_confirmed_email_subject
      .gsub('{!Contact.FirstName}', @recipient.first_name)
      .gsub('{!Contact.LastName}', @recipient.last_name)
      .gsub('{!Program.Title}', @program_title)
      .gsub('{!Program.Site}', @program_site)
      .gsub('{!Timeslot}', @timeslot).html_safe
  end

  def invite_to_fb(user, fb_url, program_title)
    @user = user
    @fb_url = fb_url
    @program_title = program_title

    mail to: user.email, subject: "#{program_title} is starting soon - Please join our Facebook group"
  end
end
