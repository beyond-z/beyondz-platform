require 'salesforce'

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

  # Finds the lead owner from the uploaded spreadsheet mapping, or returns
  # a default if it doesn't exist for our combination of fields.
  #
  # Returns a user's email address.
  def lead_owner
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

    # IF all else fails, assign it to Abby and she'll handle it manually
    if mapping.empty?
      return Rails.application.secrets.default_lead_owner
    end

    mapping.first.lead_owner
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

  # Returns true if a new Lead was created, returns false
  # if it found an existing contact to reuse. Throws on error.
  def create_on_salesforce
    salesforce = BeyondZ::Salesforce.new
    client = salesforce.get_client

    # Does this user already exist on Salesforce as a manually entered contact?
    # If we, we want to use it directly instead of trying to create a lead.

    salesforce_existing_record = client.http_get("/services/data/v#{client.version}/query?q=" \
      "SELECT Id FROM Contact WHERE Email = '#{email.sub('\'', '\'\'')}'")
    sf_answer = JSON.parse(salesforce_existing_record.body)
    salesforce_existing_record = sf_answer['records']

    contact = {}

    unless salesforce_existing_record.empty?
      self.salesforce_id = salesforce_existing_record.first['Id']
    end
    # end

    contact['FirstName'] = first_name
    contact['LastName'] = last_name
    contact['Email'] = email

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
    unless salesforce_id
      # If the user is already on salesforce btw, we assume they are already
      # assigned an owner (this is likely the case when they are manually entered
      # by someone who has already formed a relationship with that person)
      salesforce_lead_owner = client.http_get("/services/data/v#{client.version}/query?q=" \
        "SELECT Id FROM User WHERE Email = '#{lead_owner.sub('\'', '\'\'')}'")
      sf_answer = JSON.parse(salesforce_lead_owner.body)
      salesforce_lead_owner = sf_answer['records']
      salesforce_lead_owner = salesforce_lead_owner.empty? ? nil : salesforce_lead_owner.first

      if salesforce_lead_owner
        contact['OwnerId'] = salesforce_lead_owner['Id']
      else
        # this is the user id we're logged into Salesforce as to use as
        # a last-resort owner if the other one fails
        contact['OwnerId'] = client.user_id
      end

      contact['IsUnreadByOwner'] = false
    end

    unless salesforce_id
      contact['City'] = city
      contact['State'] = state
    else
      # The Salesforce Contact record uses different names than the Lead
      contact['MailingCity'] = city
      contact['MailingState'] = state
    end

    contact['LeadSource'] = 'Website Signup' unless salesforce_id

    contact['Comments_Or_Questions__c'] = applicant_comments unless salesforce_id

    contact['Account_Activated__c'] = self.confirmed? unless salesforce_id

    contact['Phone'] = phone

    contact['BZ_User_Id__c'] = id
    contact['Interested_In__c'] = applicant_details
    contact['Signup_Date__c'] = created_at
    contact['Came_From_to_Visit_Site__c'] = external_referral_url
    contact['User_Type__c'] = salesforce_applicant_type
    if salesforce_id
      # On Contact, we changed the name as there's more info available on that record
      # so it had to be more specific.
      contact['Undergrad_University__c'] = university_name
    else
      contact['University_Name__c'] = university_name
    end
    contact['Anticipated_Graduation__c'] = anticipated_graduation
    if applicant_type == 'employer'
      # Industry on Contact is a custom field...
      contact[salesforce_id ? 'Industry__c' : 'Industry'] = profession
    else
      contact['Title'] = profession
    end

    # Company on Contact is a custom field...
    contact[salesforce_id ? 'Company__c' : 'Company'] = (company.nil? || company.empty?) ? "#{name} (individual)" : company

    contact['Started_College__c'] = started_college_in
    contact['Interested_in_opening_BZ__c'] = like_to_help_set_up_program ? true : false
    contact['Keep_Informed__c'] = like_to_know_when_program_starts ? true : false
    # we store the string and SF needs a string, but the library expects an array so we split it back up here
    if bz_region
      contact['BZ_Region__c'] = bz_region
    else
      contact['BZ_Region__c'] = ''
    end

    lead_created = false

    # The Lead class provided by the gem is buggy so we do it with this call instead
    # which is what Lead.save calls anyway
    unless salesforce_id
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

      client.update('Contact', salesforce_id, contact)
      lead_created = false
    end

    save!

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

  def auto_add_to_salesforce_campaign
    # We may also need to add them to a campaign if certain things
    # are right.
    cm = {}
    cm['CampaignId'] = salesforce_campaign_id

    if cm['CampaignId']
      # Can't use client.materialize because it sets the checkboxes to nil
      # instead of false which fails server-side validation. This method
      # works though.
      sf = BeyondZ::Salesforce.new
      client = sf.get_client
      cm['ContactId'] = salesforce_id
      client.create('CampaignMember', cm)
    end

    # The apply now enabled *should* be set by the SF triggers
    # but we might want to do it here now anyway to give faster
    # response to the user.
    apply_now_enabled = true
    save!
  end


  def salesforce_applicant_type
    case applicant_type
    when 'undergrad_student'
      'Undergrad'
    when 'volunteer'
      'Volunteer'
    when 'temp_volunteer'
      'Temp Volunteer'
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

  def salesforce_campaign_id
    mapping = CampaignMapping.where(
      :university_name => university_name,
      :bz_region => bz_region,
      :applicant_type => applicant_type
    )

    if mapping.empty?
      return nil
    end

    mapping.first.campaign_id
  end

  # validates :anticipated_graduation, presence: true, if: :graduation_required?
  # validates :university_name, presence: true, if: :university_name_required?

  def graduation_required?
    applicant_type == 'grad_student' || applicant_type == 'undergrad_student' ||
      applicant_type == 'school_student'
  end

  def university_name_required?
    applicant_type == 'grad_student' || applicant_type == 'undergrad_student'
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
