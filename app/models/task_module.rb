class TaskModule < ActiveRecord::Base
  has_many :sections, class_name: 'TaskSection'
end