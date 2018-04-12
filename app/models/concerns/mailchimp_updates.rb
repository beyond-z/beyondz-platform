module MailchimpUpdates
  extend ActiveSupport::Concern

  included do
    before_save :update_mailchimp
  end
  
  def create_mailchimp
    # don't create if model doesn't have a salesforce_id (temporary champion issue)
    return true unless attributes.has_key?('salesforce_id ')
    
    # don't create if we're still waiting for a valid salesforce_id
    return true if salesforce_id.nil?
    
    mailchimp = BeyondZ::Mailchimp::User.new(self)
    
    success_status = mailchimp.create
  end
  
  def update_mailchimp
    # don't update for a new record, it doesn't exist in mailchimp yet
    return true if new_record?

    mailchimp = BeyondZ::Mailchimp::User.new(self)

    success_status = mailchimp.update

    # for now, assume success until retro-sync can be performed
    success_status = true

    unless success_status
      self.errors[:email] << "could not be updated on MailChimp"
    end

    success_status
  end
end
