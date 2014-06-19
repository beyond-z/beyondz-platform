class TaskResponse < ActiveRecord::Base

  belongs_to :task
  belongs_to :task_section

end