class Champion < ActiveRecord::Base
  self.primary_key = "id"

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :industries, presence: true
  validates :studies, presence: true
  validates :linkedin_url, presence: true

  def create_on_salesforce
    mapping = CampaignMapping.where(
      :applicant_type => 'braven_champion'
    )
    return if mapping.empty?

    campaign_id = mapping.first.campaign_id

    salesforce_id = nil

    salesforce = BeyondZ::Salesforce.new
    client = salesforce.get_client
    client.materialize('Contact') # Added this b/c sometimes when accessing an existing record before the fields below were added, was getting: ArgumentError (No attribute named LinkedIn_URL__c)
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
    # BZ_Region is required, so if they don't choose a region default them to National
    contact['BZ_Region__c'] = region.blank? ? 'National' : region
    contact['Signup_Date__c'] = created_at
    contact['User_Type__c'] = 'Champion'
    contact['Champion_Information__c'] = 'Current'


    if was_new
      contact = client.create('Contact', contact)
      salesforce_id = contact['Id']
    else
      client.update('Contact', salesforce_id, contact)
    end

    cm = {}
    cm['CampaignId'] = campaign_id
    cm['ContactId'] = salesforce_id
    cm['Candidate_Status__c'] = 'Confirmed'

    begin
      client.create('CampaignMember', cm)
    rescue Databasedotcom::SalesForceError => e
      # already a campaign member, no problem swallowing the error
      Rails.logger.warn(e)
      @already_member = true # to silence rubocop's complaint that I suppressed it
    end
  end

  def name
    "#{first_name} #{last_name}"
  end

  def too_recently_contacted
    flood_check = ChampionContact.where(:champion_id => self.id).where("created_at > ?", 1.week.ago.end_of_day)
    return true if flood_check.any?

    semester_check = ChampionContact.where(:champion_id => self.id).where("created_at > ?", 3.months.ago)
    return true if semester_check.count > 3

    false
  end
end
