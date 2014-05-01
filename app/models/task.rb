class Task < ActiveRecord::Base

  belongs_to :assignment
  belongs_to :task_definition
  belongs_to :user
  has_many :files, class_name: 'TaskFile', dependent: :destroy

  scope :for_assignment, -> (assignment_id) {
    where(assignment_id: assignment_id)
  }
  scope :complete, -> { where(tasks: { state: :complete }) }
  scope :incomplete, -> { where.not(tasks: { state: :complete }) }
  scope :required, -> {
    joins(:task_definition)\
    .where(task_definitions: { required: true })
  }
  scope :not_required, -> {
    joins(:task_definition)\
    .where(task_definitions: { required: false })
  }
  scope :require_approval, -> {
    joins(:task_definition)\
    .where(task_definitions: { requires_approval: true })
  }
  scope :do_not_require_approval, -> {
    joins(:task_definition)\
    .where(task_definitions: { requires_approval: false })
  }
  scope :for_display, -> {
    joins(:task_definition).includes(:task_definition)\
    .order('task_definitions.position ASC')
  }
  scope :files, -> { where(kind: :file) }


  state_machine :state, :initial => :new do
    # Define events and allowed transitions
    event :submit do
      transition :new => :complete,
        :if => lambda { |task| !task.task_definition.requires_approval? }
      transition [:new, :pending_revision] => :pending_approval
    end

    event :request_revision do
      transition :pending_approval => :pending_revision
    end

    event :approve do
      transition :pending_approval => :complete
    end

    # Define state transition callbacks
    after_transition any => :pending_approval, :do => :send_to_approver
    after_transition :pending_approval => :pending_revision,
      :do => :send_back_to_user
    after_transition any => :complete, :do => :post_completion_check

    # Definte state attributes/methods
    state all - [:new, :complete] do
      def in_progress?
        true
      end
    end

    state :new, :complete do
      def in_progress?
        false
      end
    end

    state :new, :pending_revision do
      def submittable?
        assignment.in_progress?
      end
    end

    state :pending_approval, :complete do
      def submittable?
        false
      end
    end

  end


  ## State machine callbacks

  def send_to_approver
    # request approval from coach
  end

  def send_back_to_user
    # request revision from user
  end

  def post_completion_check
    # if all tasks are complete, notify coach?
    # lock tasks?
    
    validated = assignment.validate_tasks
  end

  def file?
    (kind == 'file')
  end

  def needs_files?
    file? && (files.count < 1)
  end

  # blank out uploaded file data
  def reset_files
    files.each do |file|
      # if attachment type exists, delete it
      if type_exists?(file_type)
        file.reset(file_type)
      end
    end
  end

  def delete_files
    files.each do |file|
      file.reset(file_type)
      file.destroy
    end
  end
end
