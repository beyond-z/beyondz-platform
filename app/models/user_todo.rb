class UserTodo < ActiveRecord::Base
  belongs_to :user
  belongs_to :todo
end
