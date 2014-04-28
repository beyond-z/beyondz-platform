class RemoveTodosTable < ActiveRecord::Migration
  def change
  	drop_table :todo_definitions
  	drop_table :todos
  end
end
