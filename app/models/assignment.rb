class Assignment < ActiveRecord::Base
  belongs_to :assignment_definition
  belongs_to :user
  has_many :submissions
  has_many :todos

  belongs_to :assignment_definition
  belongs_to :user
  has_many :tasks, dependent: :destroy

  scope :complete, -> { all.reject{|a| a.tasks.incomplete.count > 0 } }
  scope :incomplete, -> { all.reject{|a| a.tasks.incomplete.count == 0 } }
  scope :for_display, -> { joins(:assignment_definition).\
    includes(:assignment_definition).\
    order("assignment_definitions.start_date ASC") }


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
    after_transition :on => :started, :do => :accept
    after_transition :on => :pending_approval, :do => :send_to_approver
    after_transition :on => :pending_revision, :do => :send_back_to_user
    before_transition :on => :complete, :do => :verify_assignment_completion
    after_transition :on => :complete, :do => :post_completion_check

    # Definte state attributes/methods
    state all - [:new, :completed] do
      def in_process?
        true
      end
    end

    state :new, :completed do
      def in_process?
        false
      end
    end

  end


  def initialize
    # NOTE: This *must* be called, otherwise states won't get initialized
    super()
  end

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

  def verify_assignment_completion
    # verify all requirements are fulfilled before allowing completion
  end

  def post_completion_check
    # if all assignments are complete, notify coach?
    # lock assignments?
  end

end