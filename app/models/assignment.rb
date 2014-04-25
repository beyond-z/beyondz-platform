class Assignment < ActiveRecord::Base
  belongs_to :assignment_definition
  belongs_to :user
  has_many :submissions
  has_many :todos

  scope :complete, -> { all.reject { |a| a.todos.incomplete.count > 0 } }
  scope :incomplete, -> { all.reject { |a| a.todos.incomplete.count == 0 } }
end
