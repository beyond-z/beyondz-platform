class RemoveUserTodoStatuses < ActiveRecord::Migration
  def change
    drop_table :user_todo_statuses
  end
end
