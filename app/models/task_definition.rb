class TaskDefinition < ActiveRecord::Base

  belongs_to :assignment_definition
  has_many :tasks, dependent: :destroy


  default_scope order('position ASC')

end
