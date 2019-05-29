require 'salesforce'
require 'mailchimp/user'

# Monkey-patch the CAS gem so we can use it without losing the database
# features we use for SSO - we still manage the users here, including
# their passwords in this database, but we want to use the CAS server
# for typical user login so it is seamless with Canvas.
#
# As a result, we do want database_authenticatable, and it is nice to keep
# its routes as a fallback. We just ALSO want cas_authenticatable and would
# prefer to use its routes in the views when we can.
#
# Without this, database_authenticatable and cas_authenticatable are incompatible
# because they both try to define user_sign_in_path, etc.

ActionDispatch::Routing::Mapper.class_eval do
  # This code is copy/pasted from the devise_cas_authenticatable gem's source code,
  # then modified to fit our interoperability requirements and rubocop's whining.

  # The main change is the path names are suffixed with '_sso' now.

  protected

  def devise_cas_authenticatable(mapping, controllers)
    sign_out_via = (Devise.respond_to?(:sign_out_via) && Devise.sign_out_via) || [:get, :post]

    # service endpoint for CAS server
    get 'service', :to => "#{controllers[:cas_sessions]}#service", :as => 'service'
    post 'service', :to => "#{controllers[:cas_sessions]}#single_sign_out", :as => 'single_sign_out'

    resource :session, :only => [], :controller => controllers[:cas_sessions], :path => '' do
      get :new, :path => mapping.path_names[:sign_in_sso], :as => 'new_sso'
      get :unregistered
      post :create, :path => mapping.path_names[:sign_in_sso]
      match :destroy, :path => mapping.path_names[:sign_out_sso], :as => 'destroy_sso', :via => sign_out_via
    end
  end
end

# With that fixed, we can now define the regular User class.

class User < ActiveRecord::Base
  include MailchimpUpdates
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :database_authenticatable,
         :cas_authenticatable

  paginates_per 100

  has_one :enrollment, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :assignments, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true

  before_save :capitalize_name
  
  def capitalize_name
    # need to guard against this to ensure it isn't frivolously set and triggers useless external updates
    if first_name_changed?
      self.first_name = first_name.split.map(&:capitalize).join(' ') unless first_name.nil?
    end
    if last_name_changed?
      self.last_name = last_name.split.map(&:capitalize).join(' ') unless last_name.nil?
    end
  end

  # Finds the lead owner from the uploaded spreadsheet mapping, or returns
  # a default if it doesn't exist for our combination of fields.
  #
  # Returns a user's email address.
  def lead_owner_email
    # The 'other' option on the signup form should be accessible here too.
    # So if we see the keyword 'other' in the mapping, we match that to anything
    # except the item on the list we have.
    university_name_lookup = university_name
    # Blank doesn't count as other - it just means they didn't fill in this field at all
    # (they are probably the wrong applicant_type for it to be applicable)
    if !university_name_lookup.nil? && university_name_lookup != ''
      unless List.find_by_friendly_name('universities').items.include? university_name_lookup
        university_name_lookup = 'other'
      end
    end
    # Ditto, just other for bz_region.
    bz_region_lookup = bz_region
    if !bz_region_lookup.nil? && bz_region_lookup != ''
      unless List.find_by_friendly_name('bz_regions').items.include? bz_region_lookup
        bz_region_lookup = 'other'
      end
    end

    mapping = LeadOwnerMapping.where(
      :university_name => university_name_lookup,
      :bz_region => bz_region_lookup,
      :applicant_type => applicant_type
    )
    logger.debug "########## Found Lead Owner: #{mapping.inspect} for university_name_lookup = #{university_name_lookup}, bz_region_lookup = #{bz_region_lookup}, applicant_type = #{applicant_type}"

    # IF all else fails, assign it to Abby and she'll handle it manually
    if mapping.empty?
      return Rails.application.secrets.default_lead_owner
    end
    mapping.first.lead_owner
  end

  def salesforce_lead_owner_id
    sf = BeyondZ::Salesforce.new
    client = sf.get_client

    # Note on the SOQL queries rather than ActiveRecord style finds:
    #
    # SFDC_Models::User.find_by_Email(lead_owner)
    # the model didn't work though because the materialize call
    # conflicted their User with our User (the namespace wasn't used
    # properly!) So doing SOQL instead. The sub call is to escape the quotes
    # to mitigate SQL injection (of course, this comes from our code anyway,
    # so there should be no security risk, but I just prefer to be a bit
    # defensive.)
    #
    # Moreover, since the databasedotcom gem tries to materialize objects... and
    # has a bug where it ignores the module if it finds a class in global... it
    # conflicts with our User class too! So the query function is unusable :(
    # Instead, I'll go one level lower and use their http method, just like the
    # implementation (line 182 of databasedotcom/client.rb)
    salesforce_lead_owner = client.http_get("/services/data/v#{client.version}/query?q=" \
        "SELECT Id FROM User WHERE Email = '#{lead_owner_email.sub('\'', '\'\'')}'")
    sf_answer = JSON.parse(salesforce_lead_owner.body)
    salesforce_lead_owner = sf_answer['records']
    salesforce_lead_owner = salesforce_lead_owner.empty? ? nil : salesforce_lead_owner.first

    if salesforce_lead_owner
      return salesforce_lead_owner['Id']
    else
      # this is the user id we're logged into Salesforce as to use as
      # a last-resort owner if the other one fails
      return client.user_id
    end
  end

  # Salesforce IDs are a bit weird because they come in both 15 character
  # and 18 character versions. Both these are supposed to be identical, and
  # the extra chars are just provided to account for database collations that
  # are case insensitive for the 15 char version.
  #
  # Our database is case-sensitive, so we don't need those final three chars,
  # and they can be wrong - the manual URLs always give the 15 char version but
  # the api gives the 18 char version. We need our lookup to treat them both the
  # same. Thankfully, the 18 char version has the same first 15 chars, so we can
  # simply truncate it. We want to truncate both what is given and what is in the
  # database to ensure we look up the right record.
  #
  # The default find_by_salesforce_id doesn't do that, but we can redefine it and
  # get correct results for this special field.
  #
  # It is 16 in here because the end thing is not inclusive in the substr function.
  def self.find_by_salesforce_id(sid)
    where('substr(salesforce_id, 0, 16) = substr(?, 0, 16)', [sid]).first
  end

  def self.search(query)
    # where(:title, query) -> This would return an exact match of the query
    where('lower(first_name) like ? OR lower(last_name) like ? OR lower(email) like ?', "%#{query.downcase}%", "%#{query.downcase}%", "%#{query.downcase}%")
  end

  # We allow empty passwords for certain account types
  # so this enforces that. Otherwise, fall back on devise's
  # default validation for the password.
  def password_required?
    false
    # password.empty? || super(password)
  end

  # Gotta override devise's method for this too because while we
  # allow accounts to be stored with empty passwords, that is not
  # considered valid to log in - such an account should be saved
  # but not usable as an end user login.
  def valid_password?(password)
    if password.nil? || password == ''
      false # never allow login with an empty password
    else
      super(password) # otherwise, let devise check it from the database
    end
  end

  # When a lead is converted on SF, call this and it will update it to
  # contact here. If it isn't a contact, the campaigns won't work and the
  # pages will be slower to load. This should only be called once, or else
  # it might double add on other services! See is_converted_on_salesforce.
  def record_converted_on_salesforce(contact_id)
    self.salesforce_id = contact_id
    self.is_converted_on_salesforce = true
    self.save!

    self.auto_add_to_salesforce_campaign
    self.create_mailchimp
  end

  # Returns true if a new Lead was created, returns false
  # if it found an existing contact to reuse. Throws on error.
  def create_on_salesforce(as_contact = false)
    salesforce = BeyondZ::Salesforce.new
    client = salesforce.get_client

    working_on_contact = as_contact

    # if we are going to auto add to a campaign anyway, skip the Lead
    # step and work directly on a contact
    if !salesforce_campaign_id.nil?
      working_on_contact = true
    end

    # Does this user already exist on Salesforce as a manually entered contact?
    # If we, we want to use it directly instead of trying to create a lead/contact.
    existing_salesforce_id = salesforce.exists_in_salesforce(email)
    unless existing_salesforce_id.nil?
      self.salesforce_id = existing_salesforce_id

      working_on_contact = true
    end

    contact = {}

    contact['FirstName'] = first_name.split.map(&:capitalize).join(' ')
    contact['LastName'] = last_name.split.map(&:capitalize).join(' ')
    contact['Email'] = email

    # If the user is already on salesforce btw, we assume they are already
    # assigned an owner (this is likely the case when they are manually entered
    # by someone who has already formed a relationship with that person)
    unless working_on_contact
      contact['OwnerId'] = salesforce_lead_owner_id
      contact['IsUnreadByOwner'] = false
    end

    unless working_on_contact
      contact['City'] = city
      contact['State'] = state
    else
      # The Salesforce Contact record uses different names than the Lead
      contact['MailingCity'] = city
      contact['MailingState'] = state
    end

    contact['LeadSource'] = 'Website Signup' unless working_on_contact

    contact['Comments_Or_Questions__c'] = applicant_comments unless working_on_contact

    contact['Account_Activated__c'] = self.confirmed? unless working_on_contact

    contact['Phone'] = phone

    contact['BZ_User_Id__c'] = id
    contact['Interested_In__c'] = applicant_details
    contact['Signup_Date__c'] = created_at
    contact['Came_From_to_Visit_Site__c'] = external_referral_url
    contact['User_Type__c'] = salesforce_applicant_type
    if working_on_contact
      # On Contact, we changed the name as there's more info available on that record
      # so it had to be more specific.
      contact['Undergrad_University__c'] = university_name
    else
      contact['University_Name__c'] = university_name
    end
    contact['Anticipated_Graduation__c'] = anticipated_graduation
    contact['Anticipated_Graduation_Semester__c'] = anticipated_graduation_semester
    if applicant_type == 'employer'
      # Industry on Contact is a custom field...
      contact[working_on_contact ? 'Industry__c' : 'Industry'] = profession
    else
      contact['Title'] = profession
    end

    # Company on Contact is a custom field...
    contact[working_on_contact ? 'Company__c' : 'Company'] = (company.nil? || company.empty?) ? "#{name} (individual)" : company

    contact['Started_College__c'] = started_college_in
    contact['Enrollment_Semester__c'] = started_college_in_semester
    contact['Interested_in_opening_BZ__c'] = like_to_help_set_up_program ? true : false
    contact['Keep_Informed__c'] = like_to_know_when_program_starts ? true : false
    # TODO: for uni partner signups, employer partner signups and other, create a BZRegionMapping admin option
    # that looks up the BZ Region based on the name in the form.  E.g. map 'Rutgers University - Newark' to 'Newark, NJ'
    # Right now, they just turn into a lead with National set as the region and then if they are assigned to a Campaign
    # with the BZ Region set, that's when their region is updated.
    #
    # BZ_Region is required, so if it's not set, default them to National
    contact['BZ_Region__c'] = (region.blank? || region.strip == 'Other:') ? 'National' : region

    lead_created = false
    add_to_campaign = false

    # The Lead class provided by the gem is buggy so we do it with this call instead
    # which is what Lead.save calls anyway
    unless working_on_contact
      # If the salesforce_id is already set, they are a person created
      # manually who is now signing up.
      #
      # If it isn't set, we create a lead.
      contact = client.create('Lead', contact)

      self.salesforce_id = contact['Id']

      lead_created = true
    else
      # And if salesforce_id is set already, we found an existing Contact,
      # so we update that record instead
      if salesforce_id
        client.update('Contact', salesforce_id, contact)
        lead_created = false
      else
        contact = client.create('Contact', contact)
        self.salesforce_id = contact['Id']
        self.is_converted_on_salesforce = true # we creating converted immediately
        lead_created = false
        # new contacts should be added to the campaign without even waiting
        add_to_campaign = true
      end
    end

    save!

    if add_to_campaign
      auto_add_to_salesforce_campaign
      # and we create on mailchimp when creating on SF too
      self.create_mailchimp
    end

    lead_created
  end

  def confirm_on_salesforce
    salesforce = BeyondZ::Salesforce.new
    client = salesforce.get_client
    client.materialize('Lead')
    begin
      lead = SFDC_Models::Lead.find(salesforce_id)
      lead.Account_Activated__c = true
      lead.save
    rescue Databasedotcom::SalesForceError
      # Failure is OK, it just means they were already converted to a contact
      #
      # We should then go ahead and kick off the post-conversion steps by
      # adding to the salesforce campaign

      auto_add_to_salesforce_campaign
    end
  end

  def ensure_in_salesforce_campaign_for(bz_region, university_name, applicant_type)
if false
    mapping = nil
    if bz_region.nil?
      mapping = CampaignMapping.where(
        :university_name => university_name,
        :applicant_type => applicant_type
        )
    else
      mapping = CampaignMapping.where(
        :bz_region => bz_region,
        :applicant_type => applicant_type
        )
    end
    if mapping.empty?
      logger.debug "########## No campaign mapping found for region #{bz_region}, university #{university_name}, #{applicant_type}"
      raise Exception.new "no SF campaign setup"
    end

    cid = mapping.first.campaign_id
end

    cid = "70117000001am1C"

    cm = {}
    cm['CampaignId'] = cid

    # Can't use client.materialize because it sets the checkboxes to nil
    # instead of false which fails server-side validation. This method
    # works though.
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    cm['ContactId'] = salesforce_id

    begin
      cm = client.create('CampaignMember', cm)
      Rails.cache.delete("salesforce/user_campaigns/#{salesforce_id}")
    rescue Databasedotcom::SalesForceError => e
      # If this failure happens, it is almost certainly just because they
      # are already in the campaign 
      logger.info e
    end

    return cid
  end

  def auto_add_to_salesforce_campaign(candidate_status = nil, selected_timeslot = nil)
    # We may also need to add them to a campaign if certain things
    # are right.
    cm = {}
    cm['CampaignId'] = salesforce_campaign_id
    cm['Candidate_Status__c'] = candidate_status unless candidate_status.nil?
    cm['Volunteer_Event_Signups__c'] = selected_timeslot unless selected_timeslot.nil?
    cm['Opted_Out_Reason__c'] = '' # Reset this in case they cancel but then signup again.

    if cm['CampaignId']
      # Can't use client.materialize because it sets the checkboxes to nil
      # instead of false which fails server-side validation. This method
      # works though.
      sf = BeyondZ::Salesforce.new
      client = sf.get_client
      cm['ContactId'] = salesforce_id

      begin
        cm = client.create('CampaignMember', cm)
        Rails.cache.delete("salesforce/user_campaigns/#{salesforce_id}")
      rescue Databasedotcom::SalesForceError => e
        # If this failure happens, it is almost certainly just because they
        # are already in the campaign - probably because we invited them from
        # Salesforce, so we can simply proceed normally and let the campaign
        # member check in the welcome page show them next steps, assuming
        # apply now will work until triggers hit us to say otherwise.
        #
        # However, for Event Volunteers they maybe rescheduling or signing up again after cancelling, so we want to
        # update their record with the new information
        if applicant_type == 'event_volunteer'
          client.materialize('CampaignMember')
          cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(salesforce_id, salesforce_campaign_id)
          if !cm.nil?
            cm.Candidate_Status__c = candidate_status unless candidate_status.nil?
            unless selected_timeslot.nil?
              if cm.Volunteer_Event_Signups__c.nil? || cm.Volunteer_Event_Signups__c == ''
                # This is the first event they're signing up for.
                cm.Volunteer_Event_Signups__c = selected_timeslot
              else
                # If they signup for a second event, create a line delimited list of events they signed up for.
                cm.Volunteer_Event_Signups__c = "#{cm.Volunteer_Event_Signups__c}\n#{selected_timeslot}"
              end
            end
            # Reset this in case they cancel but signup again.
            cm.Opted_Out_Reason__c = ''
            cm.save
          else
            logger.debug "########## No CampaignMember found with salesforce_id = #{salesforce_id} and salesforce_campaign_id = #{salesforce_campaign_id}.  Failed to update their event volunteer signup info"
          end
        else
          logger.debug "Caught #{e} -- which usually means that the CampaignMember already exists in Salesforce, which is fine."
        end
      end

      # The apply now enabled *should* be set by the SF triggers
      # but we might want to do it here now anyway to give faster
      # response to the user.
      self.apply_now_enabled = true
      self.save!
      return cm
    else
      logger.debug "No 'salesforce_campaign_id' found for #{inspect}.  Can't create a Campaign Member."
      return nil
    end
  end

  def cancel_volunteer_signup(selected_timeslot, cancellation_reason = nil)
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')
    cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(salesforce_id, salesforce_campaign_id)
    if !cm.nil?
      if cm.Volunteer_Event_Signups__c == selected_timeslot
        # Exact match means they are cancelling the only timeslot they signed up for
        cm.Volunteer_Event_Signups__c = ''
        cm.Candidate_Status__c = 'Opted Out'
        cm.Opted_Out_Reason__c = 'Cancelled Volunteer Signup'
      elsif !cm.Volunteer_Event_Signups__c.nil? && cm.Volunteer_Event_Signups__c.include?(selected_timeslot)
        # If this timeslot is in the list, they signed up for multiple and we just want to remove the one
        # they're cancelling from the list.
        # Note: this handles both \r\n and just \n since they may manually edit the list in an editor
        # that inserts a carriage return

        # First handle removing it from the beginning or middle of the list
        cm.Volunteer_Event_Signups__c.slice! "#{selected_timeslot}\r\n"
        cm.Volunteer_Event_Signups__c.slice! "#{selected_timeslot}\n"
        # Now handle removing it from the end of the list.
        cm.Volunteer_Event_Signups__c.slice! "\r\n#{selected_timeslot}"
        cm.Volunteer_Event_Signups__c.slice! "\n#{selected_timeslot}"
      end
      cm.save

      sf = BeyondZ::Salesforce.new
      client = sf.get_client
      campaign = sf.load_cached_campaign(cm.CampaignId)
      client.materialize('Task')
      task = SFDC_Models::Task.new
      task.OwnerId = campaign.OwnerId
      task['Subject'] = "Cancelled Volunteer Signup for #{first_name} #{last_name}: #{selected_timeslot}"
      description = "This person signed up for '#{selected_timeslot}' but then cancelled"
      description = "#{description} citing this as the reason\n\n'#{cancellation_reason}'" unless cancellation_reason.nil? || cancellation_reason == ''
      task['Description'] = description
      task['ActivityDate'] = DateTime.now
      task.WhoId = cm.ContactId
      task.WhatId = cm.CampaignId
      task.Status = 'Completed'
      task['CampaignMemberId__c'] = cm.Id
      task.IsReminderSet = false
      task.IsRecurrence = false
      task.save
    else
      logger.debug "No CampaignMember found with salesforce_id = #{salesforce_id} and salesforce_campaign_id = #{salesforce_campaign_id}.  Failed to set Candidate Status to cancel their Event Volunteer Signup"
    end
  rescue Databasedotcom::SalesForceError => e
    logger.warn "###### Caught Databasedotcom::SalesForceError #{e.inspect} -- Failed to update CampaignMember and record a Task of the cancellation for #{first_name} #{last_name} - #{selected_timeslot}"
  end
  
  def region
    region_by_university = Hash.new(nil).merge({
      'National Louis University' => 'Chicago',
      'San Jose State University' => 'San Francisco Bay Area, San Jose',
      'Rutgers University - Newark' => 'Newark, NJ'
    })
    
    bz_region || region_by_university[university_name]
  end

  def nlu_student_id
    enrollment = Enrollment.find_by_user_id(self.id)
    sid = nil
    sid = enrollment.student_id unless enrollment.nil?
    if !sid.nil? && sid.starts_with?("N00")
      return sid
    else
      return nil # not a NLU ID...
    end
  end

  def salesforce_applicant_type
    case applicant_type
    when 'undergrad_student'
      'Undergrad'
    when 'preaccelerator_student'
      'Undergrad'
    when 'leadership_coach'
      'Leadership Coach'
    when 'professional_mentor'
      'Professional Mentor'
    when 'volunteer' # Old value here for backwards compatibility
      'Leadership Coach'
    when 'event_volunteer'
      'Event Volunteer'
    when 'temp_volunteer' # Old value here for backwards compatibility
      'Event Volunteer'
    when 'employer'
      'Employer'
    when 'partner'
      'University'
    when 'other'
      'Other'
    else
      applicant_type
    end
  end

  def override_salesforce_campaign_id(override_value)
    @salesforce_campaign_id = override_value
  end

  def salesforce_campaign_id
    return @salesforce_campaign_id if defined?(@salesforce_campaign_id)
    
    mapping = nil
    # For Event Volunteers, they may have been a Fellow or a Coach in the past and thus have their university_name set,
    # however, we don't use university_name when looking up the Campaign for that region, so the mapping is not found.
    if applicant_type == 'event_volunteer'
      mapping = CampaignMapping.where(
        :bz_region => bz_region,
        :applicant_type => applicant_type
      )
      if mapping.empty?
        logger.debug "########## No campaign mapping found for #{bz_region}, #{applicant_type}"
        return nil
      end
    else
      mapping = CampaignMapping.where(
        :university_name => university_name,
        :bz_region => bz_region,
        :applicant_type => applicant_type
      )
      if mapping.empty?
        logger.debug "########## No campaign mapping found for #{university_name}, #{bz_region}, #{applicant_type}"
        return nil
      end
    end

    @salesforce_campaign_id = mapping.first.campaign_id
  end

  # The BZ Region that this user is mapped to given their Calendar Email and Application Type
  def self.get_bz_region(applicant_type, calendar_email)
    mapping = CampaignMapping.where(
      :calendar_email => calendar_email,
      :applicant_type => applicant_type
    )

    if mapping.empty?
      logger.debug "########## No BZ Region found for this calendar_email = #{calendar_email} and applicant_type=#{applicant_type}."
      return nil
    end

    mapping.first.bz_region
  end

  # Returns the URL of the calendly calendar of volunteer events for the specified
  # bz_region
  def self.get_calendar_url(bz_region)
    mapping = CampaignMapping.where(
      :bz_region => bz_region,
      :applicant_type => 'event_volunteer'
    )

    if mapping.empty?
      logger.debug "########## No calendar_email found for this bz_region = #{bz_region}"
      return nil
    end

    # Examples:
    # https://calendly.com/run-volunteers
    # https://calendly.com/sjsu-volunteers
    # https://calendly.com/stagingbraven

    mapping.first.calendar_url
  end

  # validates :anticipated_graduation, presence: true, if: :graduation_required?
  # validates :university_name, presence: true, if: :university_name_required?

  def graduation_required?
    applicant_type == 'grad_student' || applicant_type == 'undergrad_student' ||
      applicant_type == 'school_student' || applicant_type == 'preaccelerator_student'
  end

  def university_name_required?
    applicant_type == 'grad_student' || applicant_type == 'undergrad_student' || applicant_type == 'preaccelerator_student'
  end

  after_create :create_child_skeleton_rows

  def name
    "#{first_name} #{last_name}"
  end

  # Obsolete - used to be a field used by staff to manually mark off which candidates where owned by who
  # Now we use Salesforce lead mapping.
  def relationship_manager?
    !relationship_manager.nil?
  end

  def days_since_last_activity
    # this is descending order of the latest thing, using || to fallback
    # if the value is nil.
    #
    # It would be nice if we can also fetch the Canvas time somehow but
    # that isn't available in this model right now.
    last_seen = current_sign_in_at || last_sign_in_at || created_at
    difference = DateTime.now - last_seen.to_datetime
    difference.floor # round to nearest day
  end

  # This is obsolete. Need to remove at some point
  def student?
    applicant_type == 'student'
  end

  def in_lms?
    !canvas_user_id.nil?
  end

  def admin?
    is_administrator
  end

  # Resets all assignments and tasks to an initial, unfinished
  # state.
  def reset_assignments!
    assignments.each(&:destroy!)
    tasks.each(&:destroy!)

    # re-recreate them after destroying to get fresh data
    create_child_skeleton_rows
  end

  # TODO: the assignments, tasks, and submissions code is obsolete. This takes up room in the database.
  # Do a project to remove the objects and tables.
  #
  # This will create the skeletons for assignments, tasks,
  # and submissions based on the definitions. We should run
  # this whenever a user is created or a definition is added.
  #
  # Don't forget to update this code if we add any more has_many
  # relationships with the same skeleton row pattern.
  def create_child_skeleton_rows
    ActiveRecord::Base.transaction do
      AssignmentDefinition.all.each do |a|
        assignment = assignments.find_by_assignment_definition_id(a.id)
        if assignment.nil?
          assignment = Assignment.create(
            assignment_definition_id: a.id,
            state: 'new'
          )
          assignments << assignment
        end

        a.task_definitions.each do |td|
          task = tasks.find_by_task_definition_id(td.id)
          if task.nil?
            task = Task.create(
              task_definition_id: td.id,
              assignment_id: assignment.id,
              state: 'new'
            )
            tasks << task
          end
        end
      end
    end
  end

  def recent_task_activity
    result = []
    tasks.each do |a|
      if a.complete? || a.pending_approval? || (a.comments.any? && !a.complete?)
        result.push(a)
      end
    end
    result = result.sort_by { |h| h[:time_ago] }
    result
  end

  def self.send_reminders
    next_assignment = Assignment.next_due

    User.all.each do |user|
      total_count = 0
      total_done = 0
      next_assignment.todos.each do |todo|
        total_count += 1
        user.user_todos.each do |status|
          if status.todo_id == todo.id && status.completed
            total_done += 1
          end
        end
      end
      if total_count != total_done
        Reminders.assignment_nearly_due(
          user.email,
          user.name,
          next_assignment.title,
          'https://join.bebraven.org/assignments/' +
          next_assignment.seo_name)
          .deliver
      end
    end
  end
end

class LoginException < StandardError
  def initialize(message)
    @message = message
  end

  attr_reader :message
end
