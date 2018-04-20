require 'digest/sha2'
class ChampionsForwarderMailer < ActionMailer::Base
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@champions.bebraven.org>" }

  def forward_message(to_party, champion_contact, subject, text_message, html_message, attachments)

    recipient = nil
    from = nil

    if to_party == 'c'
      recipient = champion_contact.champion_email
      from = champion_contact.fellow_email_with_name
    else
      recipient = champion_contact.fellow_email
      from = champion_contact.champion_email_with_name
    end

    @text_message = text_message
    @html_message = html_message
    mail(
          to: recipient,
          subject: "Connect with Braven Fellow",
          from: from
    )

    # FIXME: attachments
  end
end
