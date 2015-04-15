class DeviseMailer < Devise::Mailer

  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@beyondz.org>" }

  def confirmation_instructions(record, token, opts = {})
    mail = super
    # your custom logic
    sf = BeyondZ::Salesforce.new
    mail.subject = sf.get_welcome_email_subject
    mail
  end
end
