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
    contact = client.create('Lead', contact)

    salesforce_id = contact['Id']

    cm = {}
    cm['CampaignId'] = campaign_id
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    cm['ContactId'] = salesforce_id

    cm = client.create('CampaignMember', cm)
  end
end
