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

  has_one :enrollment, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :tasks

  has_many :coach_students, foreign_key: :coach_id
  has_many :students, through: :coach_students, :source => :student

  validates :first_name, presence: true
  validates :last_name, presence: true

  # Finds the lead owner from the uploaded spreadsheet mapping, or returns
  # a default if it doesn't exist for our combination of fields.
  #
  # Returns a user's email address.
  def lead_owner
    mapping = LeadOwnerMapping.where(
      :state => state,
      :interested_joining => interested_joining,
      :applicant_type => applicant_type
    )

    # IF all else fails, assign it to Abby and she'll handle it manually
    if mapping.empty?
      return 'abby.whitbeck@beyondz.org'
    end

    mapping.first.lead_owner
  end

  def create_on_salesforce
    salesforce = BeyondZ::Salesforce.new
    client = salesforce.get_client

    contact = {}
    contact['FirstName'] = first_name
    contact['LastName'] = last_name
    contact['Email'] = email

    client.materialize('User')
    salesforce_lead_owner = SFDC_Models::User.find_by_Email(lead_owner)

    if salesforce_lead_owner
      contact['OwnerId'] = salesforce_lead_owner.Id
    else
      # this is the user id we're logged into Salesforce as to use as
      # a last-resort owner if the other one fails
      contact['OwnerId'] = client.user_id
    end

    contact['IsUnreadByOwner'] = false

    contact['Company'] = "#{name} (individual)"

    contact['City'] = city
    contact['State'] = state

    contact['LeadSource'] = 'Website Signup'

    # The Lead class provided by the gem is buggy so we do it with this call instead
    # which is what Lead.save calls anyway
    client.create('Lead', contact)

    self.salesforce_id = contact['Id']
    save!

    # This code is probably obsolete, but kept as an example
    # of how to do it in case we want it back later. It creates
    # a Task on Salesforce, assigned to the contact owner, telling
    # them to make initial contact.
    #
    # It is obsolete because the new design uses a salesforce
    # workflow instead.
    #
    # client.materialize('Task')
    # task = SFDC_Models::Task.new
    # task.Status = 'Not Started'
    # task.Subject = 'Initial contact'
    # task.WhoId = contact['Id']
    # task.OwnerId = contact['OwnerId']
    # task.IsReminderSet = false
    # task.Type = 'Email'
    # task.Description = 'Send the welcome email to the new user and initiate one-on-one contact.'
    # task.save
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

  def coach
    CoachStudent.find_by(student_id: id).try(:coach)
  end

  # We do need to decide exactly how users will be accepted
  # into the program and as what roles. For now, it will just
  # see if we added any students in the admin, thus making them
  # a coach, or if not, the applicant type is set if they enrolled
  # thus telling us they aren't a full student yet. (This realistically
  # only separates our seed data from real data - which is fine until
  # we start actually accepting people.)
  #
  # This method may be obsolete given the shift to Canvas - a coach
  # is now a TA in that system rather than a special user here.
  def coach?
    students.any?
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
    assignments.each do |a|
      a.destroy!
    end
    tasks.each do |t|
      t.destroy!
    end

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
          'http://platform.beyondz.org/assignments/' +
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
