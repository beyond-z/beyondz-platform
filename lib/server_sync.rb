require 'salesforce'
require 'mailchimp/user'
require 'mailchimp/interest'

class ServerSync
  attr_reader :subject, :salesforce
  
  def initialize user_or_champion
    @subject = user_or_champion
    @salesforce = BeyondZ::Salesforce.new
    @success = true
  end
  
  def verify
    outputs = []
    
    outputs << "\nProposed mailchimp groups, please verify that these are what we expect:\n  - #{local_interests.join("\n  - ")}\n\n"
    
    outputs << "Do we have a valid mailchimp record? #{boolean(valid_mailchimp_record?)}\n\n"
    
    if valid_mailchimp_record?
      outputs << "Verifying that the mailchimp record matches what we expect:"

      outputs << "  - salesforce id? #{boolean(mailchimp_salesforce_id_matches?)}"
      outputs << "  - email? #{boolean(mailchimp_email_matches?)}"
      outputs << "  - name? #{boolean(mailchimp_name_matches?)}"
      outputs << "  - region? #{boolean(mailchimp_region_matches?)}"
      outputs << "  - mailchimp groups? #{boolean(mailchimp_groups_match?)}"
      outputs << "  - newsletter options? #{boolean(mailchimp_newsletter_match?)}"
    end

    outputs << "\nDo we have a valid salesforce record? #{boolean(salesforce_id_matches?)}\n\n"
    
    if salesforce_id_matches?
      outputs << "Verifying that the salesforce record matches what we expect:"

      outputs << "  - email? #{boolean(salesforce_email_matches?)}"
      outputs << "  - name? #{boolean(salesforce_name_matches?)}"
      outputs << "  - preferred region? #{boolean(salesforce_preferred_region_matches?)}"
      outputs << "  - all regions include region? #{boolean(salesforce_all_regions_matches?)}"
      outputs << "  - campaign_id(#{subject.salesforce_campaign_id})? #{boolean(salesforce_campaign_id_matches?)}"
      
      if subject.program_semester
        outputs << "  - program semester? #{boolean(salesforce_program_semester_matches?)}"
      end
    end
    
    outputs << "\nDid all tests pass? #{boolean(@success)}"
    
    outputs.each{|output| puts output}
    
    @success
  end
  
  def salesforce_id_matches?
    subject.salesforce_id == salesforce_contact_id
  end
  
  def salesforce_email_matches?
    subject.email == salesforce_user.Email
  end
  
  def salesforce_name_matches?
    subject.first_name == salesforce_user.FirstName &&
    subject.last_name  == salesforce_user.LastName
  end
  
  def salesforce_program_semester_matches?
    local_interests.include?("Semester - #{subject.program_semester}")
  end
  
  def salesforce_campaign_id_matches?
    return false unless salesforce_campaign_member

    # there appear to be 16 and 19 digit versions of campaign_id, both valid
    shortest_campaign_id_length = [salesforce_campaign_member.CampaignId.size, subject.salesforce_campaign_id.size].min
    salesforce_campaign_member.CampaignId[0,shortest_campaign_id_length] == subject.salesforce_campaign_id[0,shortest_campaign_id_length]
  end
  
  def salesforce_preferred_region_matches?
    salesforce_user && salesforce_user.BZ_Region__c == subject.region
  end
  
  def salesforce_all_regions_matches?
    salesforce_user && salesforce_user.All_BZ_Regions__c.include?(subject.region)
  end
  
  def valid_mailchimp_record?
    !!mailchimp_user
  end
  
  def mailchimp_salesforce_id_matches?
    mailchimp_user['merge_fields']['SFID'] == subject.salesforce_id
  end
  
  def mailchimp_email_matches?
    subject.email == mailchimp_fields[:email]
  end
  
  def mailchimp_name_matches?
    subject.first_name == mailchimp_fields[:first_name] &&
    subject.last_name  == mailchimp_fields[:last_name]
  end
  
  def mailchimp_first_name_matches?
    subject.first_name == mailchimp_fields[:first_name]
  end
  
  def mailchimp_region_matches?
    subject.region == mailchimp_fields[:region]
  end
  
  def mailchimp_groups_match?
    local_interests.sort == mailchimp_interests.sort
  end
  
  def mailchimp_newsletter_match?
    mailchimp_fields[:newsletter] == 'FALSE'
  end
  
  private
  
  def boolean condition
    @success = false unless condition
    condition ? 'YES' : 'NO'
  end
  
  def salesforce_contact_id
    return @salesforce_contact_id if defined?(@salesforce_contact_id)
    @salesforce_contact_id = salesforce.exists_in_salesforce(subject.email)
  end
  
  def salesforce_user
    return @salesforce_user if defined?(@salesforce_user)
    @salesforce_user = salesforce.record_for_contact(subject)
  end
  
  def salesforce_campaign_member
    return @salesforce_campaign_member if defined?(@salesforce_campaign_member)
    @salesforce_campaign_member = salesforce.campaign_member_for_contact(subject)
  end
  
  def local_interests
    return @local_interests if defined?(@local_interests)
    
    interest_ids = BeyondZ::Mailchimp::Interest.interests_for(subject).select{|k,v| v}.keys
    @local_interests = BeyondZ::Mailchimp::Interest.interests_by_name(interest_ids)
  end
  
  def mailchimp_interests
    return @mailchimp_interests if defined?(@mailchimp_interests)

    interest_ids = mailchimp_user['interests'].select{|k,v| v}.keys
    @mailchimp_interests = BeyondZ::Mailchimp::Interest.interests_by_name(interest_ids)
  end
  
  def mailchimp_user
    return @mailchimp_user if defined?(@mailchimp_user)
    @mailchimp_user = BeyondZ::Mailchimp::User.new(subject).mailchimp_record
  end
  
  def mailchimp_fields
    return @mailchimp_fields if defined?(@mailchimp_fields)
    
    @mailchimp_fields = {
      email: mailchimp_user['email_address'],
      first_name: mailchimp_user['merge_fields']['FNAME'],
      last_name: mailchimp_user['merge_fields']['LNAME'],
      region: mailchimp_user['merge_fields']['REGION'],
      newsletter: mailchimp_user['merge_fields']['NEWSLETTER'].upcase
    }
  end
end