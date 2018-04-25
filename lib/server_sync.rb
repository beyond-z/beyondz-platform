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
    puts "\nProposed mailchimp groups, please verify that these are what we expect:\n  - #{local_interests.join("\n  - ")}\n\n"
    
    puts "Do we have a valid mailchimp record? #{boolean(valid_mailchimp_record?)}\n\n"
    
    if valid_mailchimp_record?
      puts "Verifying that the mailchimp record matches what we expect:"

      puts "  - salesforce id? #{boolean(mailchimp_salesforce_id_matches?)}"
      puts "  - email? #{boolean(mailchimp_email_matches?)}"
      puts "  - name? #{boolean(mailchimp_name_matches?)}"
      puts "  - region? #{boolean(mailchimp_region_matches?)}"
      puts "  - mailchimp groups? #{boolean(mailchimp_groups_match?)}"
      puts
    end

    puts "Do we have a valid salesforce record? #{boolean(salesforce_id_matches?)}\n\n"
    
    if salesforce_id_matches?
      puts "Verifying that the salesforce record matches what we expect:"
      puts "  - email? #{boolean(salesforce_email_matches?)}"
      puts "  - name? #{boolean(salesforce_name_matches?)}"
      
      if subject.program_semester
        puts "  - program semester? #{boolean(salesforce_program_semester_matches?)}"
      end
    end
    
    puts "\nDid all tests pass? #{boolean(@success)}"
    
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
    BeyondZ::Mailchimp::Interest.region_for(subject) == mailchimp_fields[:region]
  end
  
  def mailchimp_groups_match?
    local_interests.sort == mailchimp_interests.sort
  end
  
  private
  
  def boolean condition
    result = condition ? 'YES' : 'NO'
    @success = false unless result
    
    result
  end
  
  def salesforce_contact_id
    return @salesforce_contact_id if defined?(@salesforce_contact_id)
    @salesforce_contact_id = salesforce.exists_in_salesforce(subject.email)
  end
  
  def salesforce_user
    return @salesforce_user if defined?(@salesforce_user)
    @salesforce_user = salesforce.record_for_contact(subject)
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
    }
  end
end