class CreateUserTodos < ActiveRecord::Migration
  def change
    create_table :user_todos do |t|
      t.references :user, index: true
      t.references :todo, index: true
      t.boolean :completed
      t.datetime :completed_at

      t.timestamps
    end
  end
end
