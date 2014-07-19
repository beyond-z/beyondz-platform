class ChangeTodoCompletedDefault < ActiveRecord::Migration
  def up
  	change_column_default :todos, :completed, false
  end

  def down
  	change_column_default :todos, :completed, nil
  end
end
