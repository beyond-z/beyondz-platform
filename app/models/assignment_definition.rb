class AssignmentDefinition < ActiveRecord::Base
  has_many :resources
  has_many :assignments, dependent: :destroy
  has_many :task_definitions, dependent: :destroy

  def self.next_due
    AssignmentDefinition.where('assignment_definitions.end_date > ?', Time.now)
      .order('end_date ASC').first
  end
end
