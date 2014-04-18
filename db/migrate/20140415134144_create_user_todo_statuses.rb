class CreateUserTodoStatuses < ActiveRecord::Migration
  def change
    create_table :user_todo_statuses do |t|
      t.references :user, index: true
      t.references :todo, index: true
      t.boolean :is_checked
      t.datetime :when_checked

      t.timestamps
    end
  end
end
