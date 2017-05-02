class Champion < ActiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :industries, presence: true
  validates :studies, presence: true

  def create_on_salesforce
    mapping = CampaignMapping.where(
      :applicant_type => 'braven_champion'
    )
    return if mapping.empty?

    campaign_id = mapping.first.campaign_id

    salesforce_id = nil

    salesforce = BeyondZ::Salesforce.new
    client = salesforce.get_client
    campaign = salesforce.load_cached_campaign(campaign_id, client)
    existing_salesforce_id = salesforce.exists_in_salesforce(email)
    was_new = false

    if existing_salesforce_id.nil?
      was_new = true
    else
      salesforce_id = existing_salesforce_id
      was_new = false
    end

    contact = {}
    contact['OwnerId'] = campaign.OwnerId if was_new
    contact['FirstName'] = first_name.split.map(&:capitalize).join(' ')
    contact['LastName'] = last_name.split.map(&:capitalize).join(' ')
    contact['Email'] = email
    contact['Phone'] = phone
    contact['Company__c'] = company
    contact['Title'] = job_title
    contact['LinkedIn_URL__c'] = linkedin_url
    contact['Industry_Experience__c'] = industries.join(', ')
    contact['Fields_Of_Study__c'] = studies.join(', ')
    contact['BZ_Region__c'] = region
    contact['Signup_Date__c'] = created_at
    contact['User_Type__c'] = 'Champion'
    contact['Volunteer_Information__c'] = 'Champion'


    if was_new
      contact = client.create('Contact', contact)
      salesforce_id = contact['Id']
    else
      client.update('Contact', salesforce_id, contact)
    end

    cm = {}
    cm['CampaignId'] = campaign_id
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    cm['ContactId'] = salesforce_id
    client.create('CampaignMember', cm)

  end
end
