module MailchimpUpdates
  extend ActiveSupport::Concern

  included do
    before_save :update_mailchimp
  end
  
  def update_mailchimp
    # don't update for a new record, it doesn't exist in mailchimp yet
    return true if new_record?

    mailchimp = BeyondZ::Mailchimp::User.new(self)

    # don't update unless an updateable field has changed
    return true unless mailchimp.requires_update?

    success_status = mailchimp.update

    # for now, assume success until retro-sync can be performed
    success_status = true

    unless success_status
      self.errors[:email] << "could not be updated on MailChimp"
    end

    success_status
  end
end
