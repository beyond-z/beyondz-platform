class TaskSection < ActiveRecord::Base

  belongs_to :task_definition
  belongs_to :module, class_name: 'TaskModule', foreign_key: :task_module_id


  default_scope { order('position ASC') }

end