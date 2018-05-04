module MailchimpUpdates
  extend ActiveSupport::Concern

  included do
    before_save :update_mailchimp
  end
  
  def create_mailchimp
    # find salesforce id locally or on SF
    ensure_salesforce_id
    
    # don't create if we're still waiting for a valid salesforce_id
    return true if salesforce_id.nil?
    
    mailchimp = BeyondZ::Mailchimp::User.new(self)
    
    success_status = mailchimp.create
  end
  
  def update_mailchimp
    # don't update for a new record, it doesn't exist in mailchimp yet
    return true if new_record?

    # find salesforce id locally or on SF
    ensure_salesforce_id

    # don't create if we're still waiting for a valid salesforce_id
    return true if salesforce_id.nil?

    mailchimp = BeyondZ::Mailchimp::User.new(self)

    success_status = mailchimp.update

    # for now, assume success until retro-sync can be performed
    success_status = true

    unless success_status
      self.errors[:email] << "could not be updated on MailChimp"
    end

    success_status
  end
  
  def program_semester
    return @program_semester if defined?(@program_semester)
    
    campaign = BeyondZ::Salesforce.new.campaign_for_contact(self)
    @program_semester = campaign ? campaign.Program_Semester__c : nil
  end
  
  def ensure_salesforce_id
    return if salesforce_id

    new_id = BeyondZ::Salesforce.new.exists_in_salesforce(email)

    # skip validations and callbacks to prevent endless update loop
    User.where(id: id).update_all(salesforce_id: new_id) if new_id
  end
end
