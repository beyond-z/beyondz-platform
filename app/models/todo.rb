class Todo < ActiveRecord::Base

	belongs_to :assignment
  belongs_to :user
  belongs_to :todo_definition

  scope :complete, -> { where({completed: true})}
  scope :incomplete, -> { where({completed: false})}

end
