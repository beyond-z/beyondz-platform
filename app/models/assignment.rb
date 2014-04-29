class Assignment < ActiveRecord::Base

  belongs_to :assignment_definition
  belongs_to :user
  has_many :tasks, dependent: :destroy

  scope :complete, -> { where(tasks_complete: true) }
  scope :incomplete, -> { where(tasks_complete: false) }
  scope :for_display, -> {
    joins(:assignment_definition).\
    includes(:assignment_definition).\
    order("assignment_definitions.start_date ASC")
  }


  state_machine :state, :initial => :new do
    # Define events and allowed transitions
    event :start do
      transition :new => :started
    end

    event :submit do
      transition [:started, :pending_revision] => :pending_approval
    end

    event :request_revision do
      transition :pending_approval => :pending_revision
    end

    event :approve do
      transition :pending_approval => :complete
    end

    # Define state transition callbacks
    after_transition :on => :start, :do => :accept
    after_transition :on => :submit, :do => :send_to_approver
    after_transition :on => :request_revision, :do => :send_back_to_user
    before_transition :on => :approve, :do => :verify_completion
    after_transition :on => :approve, :do => :post_completion_check

    # Definte state attributes/methods
    state all - [:new, :complete] do
      def in_process?
        true
      end
    end

    state :new, :complete do
      def in_process?
        false
      end
    end

  end


  ## State machine callbacks

  def accept
    # user accepted/started assignment
    # notify coach?
  end

  def send_to_approver
    # request approval from coach
  end

  def send_back_to_user
    # request revision from user
  end

  def verify_completion
    # verify all requirements are fulfilled before allowing completion
  end

  def post_completion_check
    # if all assignments are complete, notify coach?
    # lock assignments?
  end


  def tasks_completed?
    tasks.incomplete.count < 1
  end

  def tasks_completed!
    update_attribute(:tasks_complete, true)

    # For now, make assigment completion based on task completion (may change)
    update_attribute(:state, :complete)
  end

  # Run whatever validation/completion checks necessary on tasks to consider
  # them complete and set the flag on assignment
  def validate_tasks
    validated = false
    if tasks_completed?
      validated = tasks_completed!
    end

    validated
  end

end