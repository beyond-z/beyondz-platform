class Assignment < ActiveRecord::Base
  include AASM

  belongs_to :assignment_definition
  belongs_to :user
  has_many :tasks, dependent: :destroy

  scope :submitted, -> { where(state: [:pending_approval, :complete]) }
  scope :not_submitted, -> { where.not(state: [:pending_approval, :complete]) }
  scope :complete, -> { where(state: :complete) }
  scope :incomplete, -> { where.not(state: :complete) }
  scope :for_display, -> {
    joins(:assignment_definition)\
    .includes(:assignment_definition)\
    .order('assignment_definitions.start_date ASC')
  }

  
  aasm :column => :state do
    state :new, initial: true
    state :started
    state :pending_approval
    state :pending_revision
    state :complete

    event :start, :after => :accept do
      transitions :from => :new, :to => :started
    end

    event :submit, :after => :send_to_approver do
      transitions :from => [:started, :pending_revision],
        :to => :pending_approval, :guard => :ready_for_submit?
    end

    event :request_revision, :after => :send_back_to_user do
      transitions :from => :pending_approval, :to => :pending_revision
    end

    event :approve, :before => :verify_completion,
      :after => :post_completion_check do
      transitions :from => :pending_approval, :to => :complete
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


  def in_progress?
    [:started, :pending_approval, :pending_revision].include?(state.to_sym)
  end

  def submittable?
    [:started, :pending_revision].include?(state.to_sym) && ready_for_submit?
  end

  def tasks_completed?
    tasks.required.incomplete.count < 1
  end

  def tasks_completed!
    update_attribute(:tasks_complete, true)
  end

  def ready_for_submit?
    # define conditions that allow an assignment to be submittable
    tasks_complete?
  end

  def requires_files?
    tasks.files.count > 0
  end

  def human_readable_status
    status_message = ''
    if submittable?
      status_message = 'READY FOR SUBMITTAL'
    elsif in_progress?
      if pending_approval?
        status_message = 'AWAITING APPROVAL'
      else
        status_message = 'IN PROGRESS'
      end
    elsif complete?
      status_message = 'COMPLETE'
    end
    
    status_message
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
