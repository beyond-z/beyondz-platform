class AddSummaryToTasks < ActiveRecord::Migration
  def up
  	add_column :task_definitions, :summary, :text
  end

  def down
  	remove_column :task_definitions, :summary
  end
end
