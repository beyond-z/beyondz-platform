require 'digest/sha2'
class ChampionsMailer < ActionMailer::Base
  default 'from' => '"Braven" <' + Rails.application.secrets.mailer_from_email + '>'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@bebraven.org>" }

  def new_champion(recipient)
    @recipient = recipient

    sf = BeyondZ::Salesforce.new
    mail to: recipient.email, subject: sf.get_new_champion_email_subject
      .gsub('{!Contact.FirstName}', @recipient.first_name)
      .gsub('{!Contact.LastName}', @recipient.last_name)
      .gsub('{!User.Email}', ENV['CHAMPION_CONTACT_EMAIL'])
  end
end
