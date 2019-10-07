# This file is for Ruby scripts that should be run for the dev env to work.
# It should be run after the DB is setup to mimic staging/prod


def createCampaignMapping(campaign_type, bzregion, program_site, campaign_id)
  puts "Creating CampaignMapping for: #{campaign_type}, #{bzregion}, #{program_site}, #{campaign_id}"
  throw new Exception('Campaign.Type == "Referral Program" not supported yet.') if campaign_type == 'Referral Program'

  if (campaign_type == 'Program Participants' || campaign_type == 'Mentee' || campaign_type == 'Pre-Accelerator Participants')
    at = APPLICANT_TYPE[campaign_type]
    un = getUniversity(bzregion, program_site)
    CampaignMapping.create(
      :campaign_id => campaign_id,
      :applicant_type => at,
      :university_name => un
    )
  else
    # TODO: do all the ones that are the same (e.g. not Braven Network or Calendly
    throw new Exception("Campaign.Type == '#{campaign_type}' not supported yet.")
  end
end

def getUniversity(bzregion, program_site)
  case bzregion
  when 'Newark, NJ'
    'Rutgers University - Newark'
  when 'San Francisco Bay Area, San Jose'
    'San Jose State University'
  when 'Chicago' # TODO: handle BravenX
    'National Louis University'
  when 'New York City, NY'
    'Lehman College'
  else
    throw new Exception("Failed to map bzregion=#{bzregion}, program_site=#{program_site} to a University.")
  end
end

# Maps campaign Type to applicant_type
APPLICANT_TYPE = {
  'Program Participants' => 'undergrad_student',
  'Leadership Coaches' => 'leadership_coach',
  'Volunteer' => 'event_volunteer',
  'Mentor' => 'professional_mentor',
  'Mentee' => 'mentee',
  'Champion' => 'braven_champion',
  'Pre-Accelerator Participants' => 'preaccelerator_student',
  'Referral Program' => 'TODO_CANT_DETERMINE_APPLICANT_TYPE_FROM_CAMPAIGN_TYPE'
   # TODO: all four types of referrals (LC/Fellow, Referrer/Referee) use the same Type. How to disambiguate?
   # Need to use a hacky check on the name which will only work if we're consistent.
}

# Blow away existing mappings, get all the current active campaigns, and map them
def setup_campaign_mappings
  CampaignMapping.destroy_all

  sf = BeyondZ::Salesforce.new
  active_campaign_info = sf.get_all_active_campaign_mapping_info()
  
  # Note: if there are multiple active campaigns for a Type/Region combo, the dev env will just be mapped
  # arbitrarily to the last one in the list. We're assuming the BZ_CreateDeveloperCampaigns.refreshDevCampaigns()
  # has been run recently and that ensures there is only one Active campaign per combo.
  active_campaign_info['records'].each do |record|
    createCampaignMapping(record['Type'], record['BZ_Region__c'], record['Program_Site__c'], record['Id'])
  end
end

############################
# RUN THE SCRIPTS!!
setup_campaign_mappings


########
# SAMPLES of all mappings. Just to see so I can expose an endpoint in SF where we can pull the current IDs

# Fellow mapping
#CampaignMapping.create(
#  :campaign_id => '701f00000014UxMAAU',
#  :applicant_type => 'undergrad_student',
#  :university_name => 'San Jose State University'
#)

# LC mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'leadership_coach',
#  :bz_region => 'San Francisco Bay Area, San Jose'
#)

# Event Volunteer (aka Mock IVer) mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'event_volunteer',
#  :bz_region => 'Newark, NJ',
#  :calendar_email => 'run-volunteers@bebraven.org',
#  :calendar_url => 'https://calendly.com/run-volunteers'
#)

# A Pre-Accelerator Fellow
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'preaccelerator_student',
#  :university_name => 'Rutgers University - Newark'
#)

# PMentor mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'professional_mentor',
#  :bz_region => 'Newark, NJ'
#)

# PMentee mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'mentee',
#  :university_name => 'Rutgers University - Newark'
#)

# Braven Network (aka champion) mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'braven_champion',
#)

# Someone being referred to be an LC mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'referral-lc',
#  :bz_region => 'Newark, NJ'
#)

## Someone being referred to be a Fellow mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'referral-fellow',
#  :bz_region => 'Newark, NJ'
#)

# Someone referring (aka nominating) someone to be an LC mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'nominator-lc',
#  :bz_region => 'Newark, NJ'
#)

# Someone referring (aka nominating) someone to be a Fellow mapping
#CampaignMapping.create(
#  :campaign_id => 'some_id',
#  :applicant_type => 'nominator-fellow',
#  :bz_region => 'Newark, NJ'
#)


# SCRATCH:
#    file.each do |row|
#      CampaignMapping.create(
#        :campaign_id => row[0],
#        :applicant_type => row[1],
#        :university_name => row[2],
#        :bz_region => row[3],
#        :calendar_email => row[4],
#        :calendar_url => row[5]
#      )
#    end


