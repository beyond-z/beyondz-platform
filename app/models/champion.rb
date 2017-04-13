class Champion < ActiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :braven_fellow, presence: true
  validates :braven_lc, presence: true
  validates :industries, presence: true
  validates :studies, presence: true

  def create_on_salesforce
    mapping = CampaignMapping.where(
      :applicant_type => 'braven_champion'
    )
    return if mapping.empty?

    campaign_id = mapping.first.campaign_id

    contact = {}

    contact['FirstName'] = first_name.split.map(&:capitalize).join(' ')
    contact['LastName'] = last_name.split.map(&:capitalize).join(' ')
    contact['Email'] = email
    contact['Phone'] = phone
    contact['LinkedIn_URL__c'] = linkedin_url
    contact['Previous_Braven_LC__c'] = braven_lc
    contact['Previous_Braven_Fellow__c'] = braven_fellow
    contact['Industries__c'] = industries.join(', ')
    contact['Studies__c'] = studies.join(', ')
    contact = client.create('Lead', contact)

    salesforce_id = contact['Id']

    cm = {}
    cm['CampaignId'] = campaign_id
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    cm['ContactId'] = salesforce_id

    client.create('CampaignMember', cm)
  end
end
