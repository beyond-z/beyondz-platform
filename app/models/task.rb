class Task < ActiveRecord::Base
  include AASM

  belongs_to :assignment
  belongs_to :task_definition
  belongs_to :user
  has_many :files, class_name: 'TaskFile', dependent: :destroy

  has_many :comments

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


  aasm :column => :state do
    state :new, initial: true
    state :pending_approval, :after_enter => :send_to_approver
    state :pending_revision
    state :complete, :after_enter => :post_completion_check

    event :submit do
      transitions :from => :new, :to => :complete,
        :guard => :does_not_require_approval?
      transitions :from => [:new, :pending_revision], :to => :pending_approval
    end

    event :request_revision, :after => :send_back_to_user do
      transitions :from => :pending_approval, :to => :pending_revision
    end

    event :approve do
      transitions :from => :pending_approval, :to => :complete
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
    assignment.validate_tasks
  end

  def in_progress?
    [:pending_approval, :pending_revision].include?(state.to_sym)
  end

  def submittable?
    can_submit = false
    
    if assignment.in_progress?
      if (state.to_sym == :new)
        can_submit = true
      elsif state.to_sym == :pending_revision
        can_submit = true
      end
    end

    can_submit
  end

  def requires_approval?
    task_definition.requires_approval? 
  end

  def does_not_require_approval?
    !requires_approval?
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
