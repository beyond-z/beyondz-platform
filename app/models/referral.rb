require 'salesforce'

class Referral < ActiveRecord::Base
  belongs_to :referrer_user

  def create_on_salesforce
    salesforce = BeyondZ::Salesforce.new
    client = salesforce.get_client

    existing_salesforce_id = salesforce.exists_in_salesforce(referred_by_email)
    if existing_salesforce_id.nil?
      # need to make a new record for the referrer
      info = {}

      info['FirstName'] = referred_by_first_name.split.map(&:capitalize).join(' ')
      info['LastName'] = referred_by_last_name.split.map(&:capitalize).join(' ')
      info['Email'] = referred_by_email
      info['Phone'] = referred_by_phone
      info['Company__c'] = referred_by_employer # FIXME: should I copy to primary affiliation?
      info['Sourcing_Info__c'] = "Online Referrer (#{referred_by_affiliation})"

      contact = client.create('Contact', info)
      self.referrer_salesforce_id = contact['Id']
    else
      # referrer is already in Salesforce, just link it in
      self.referrer_salesforce_id = existing_salesforce_id

      url_path = "/services/data/v#{client.version}/query?q=" \
        "SELECT Sourcing_Info__c FROM Contact WHERE Id = '#{existing_salesforce_id}'"
      salesforce_existing_record = client.http_get(url_path)
      sf_answer = JSON.parse(salesforce_existing_record.body)
      salesforce_existing_record = sf_answer['records']

      existing_source = salesforce_existing_record.empty? ? '' : salesforce_existing_record.first['Sourcing_Info__c']

      info = {}
      into['Sourcing_Info__c'] = "#{existing_source}\nOnline Referrer: #{referred_by_affiliation}"

      client.update('Contact', existing_salesforce_id, info)
    end

    info = {}

    info['FirstName'] = referred_first_name.split.map(&:capitalize).join(' ')
    info['LastName'] = referred_last_name.split.map(&:capitalize).join(' ')
    info['Email'] = referred_email
    info['Phone'] = referred_phone

    info['BZ_Region__c'] = referral_location
    info['Sourcing_Info__c'] = "Referred Online By #{self.referred_first_name} #{self.referred_by_last_name}"
    info['Referred_By__c'] = self.referrer_salesforce_id

    contact = client.create('Contact', info)
    self.referred_salesforce_id = contact['Id']

    save!

    salesforce.add_to_campaign(referred_salesforce_id, salesforce_referral_campaign_id)
    salesforce.add_to_campaign(referrer_salesforce_id, salesforce_nominator_campaign_id)
  end

  def salesforce_nominator_campaign_id
    mapping = CampaignMapping.where(
      :bz_region => referral_location,
      :applicant_type => "nominator-#{referring_type}"
    )

    if mapping.empty?
      logger.debug "########## No campaign found for nominator-#{referring_type} and region #{referral_location}."
      return nil
    end

    mapping.first.campaign_id
  end

  def salesforce_referral_campaign_id
    mapping = CampaignMapping.where(
      :bz_region => referral_location,
      :applicant_type => "referral-#{referring_type}"
    )

    if mapping.empty?
      logger.debug "########## No campaign found for referral-#{referring_type} and region #{referral_location}."
      return nil
    end

    mapping.first.campaign_id
  end
end
