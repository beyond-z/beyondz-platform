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
  scope :for_display, -> { joins(:assignment_definition).includes(:assignment_definition).order("assignment_definitions.start_date ASC") }

end
