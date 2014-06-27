class Task < ActiveRecord::Base
  include AASM

  belongs_to :assignment
  belongs_to :task_definition
  belongs_to :user
  has_many :responses, class_name: 'TaskResponse', dependent: :destroy
  has_many :comments, dependent: :destroy

  scope :for_assignment, -> (assignment_id) {
    where(assignment_id: assignment_id)
  }
  scope :submitted, -> { where.not(state: :new) }
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
  scope :need_student_attention, -> {
    where(state: [:new, :pending_revision])
  }
  scope :do_not_need_student_attention, -> {
    where(state: [:pending_approval, :complete])
  }
  scope :need_coach_attention, -> {
    where(state: [:pending_approval, :pending_revision])
  }

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

  def submitted?
    [:pending_approval, :complete].include?(state.to_sym)
  end

  # does task type meet submit requirements
  def ready_to_submit?
    # add other criteria over time
    ready_to_submit = needs_responses?

    ready_to_submit
  end

  # is task state ready to submit
  def submittable?
    assignment.in_progress? && (new? || pending_revision?)
  end

  # Used to autosubmit tasks that don't have task modules
  def submit_previous_task!
    last_task = previous
    if last_task && last_task.submittable? && !last_task.needs_responses?
      last_task.submit!
    end
  end

  def requires_approval?
    task_definition.requires_approval?
  end

  def does_not_require_approval?
    !requires_approval?
  end

  def needs_responses?
    task_definition.sections.count > responses.count
  end

  def next
    current_position = task_definition.position
    assignment_tasks = assignment.tasks
    return nil if current_position == assignment_tasks.count

    assignment.tasks.for_display.find_by(
      task_definitions: { position: current_position + 1 }
    )
  end

  def previous
    current_position = task_definition.position
    return nil if current_position == 1

    assignment.tasks.for_display.find_by( 
      task_definitions: { position: current_position - 1 }
    )
  end

  def update(task_params)
    ActiveRecord::Base.transaction do

      self.updated_at = Time.now

      if task_params
        # handle different task types
        if task_params.key?(:section)
          task_params[:section].each do |task_section_id, answers|
            # if already exists, just find it (allows user to update their task)
            task_response = TaskResponse.find_or_create_by(
              task_id: id, task_section_id: task_section_id
            )

            # handle file upload if exists
            if answers.key?(:file_upload)
              file_type = answers[:file_upload][:file_type]
              task_response.update_attributes(file_type: file_type)
              task_response.files << TaskFile.create(
                task_section_id: task_section_id,
                task_response_id: id,
                file_type => answers[:file_upload][file_type.to_sym]
              )
            else
              # shove all other response data into answers
              task_response.update_attributes(answers: answers.to_json)
            end
            responses.push(task_response)
          end
        end
      end
      
      if save!
        submit!
      end

    end
  end

end