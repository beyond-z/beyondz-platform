class TaskSection < ActiveRecord::Base

  belongs_to :task_definition
  belongs_to :module, class_name: 'TaskModule', foreign_key: :task_module_id

  enum file_type: { document: 0, image: 1, video: 2, audio: 3 }

  default_scope { order('position ASC') }

end