require 'digest/sha2'
class DeviseMailer < Devise::Mailer
  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default "Message-ID" => ->(v){"<#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@beyondz.org>"}

  def confirmation_instructions(record, token, opts = {})
    mail = super
    # your custom logic
    sf = BeyondZ::Salesforce.new
    mail.subject = sf.get_welcome_email_subject
    mail
  end
end
