class ChangeSubmissionsToTasks < ActiveRecord::Migration
  def up

  	rename_table :submissions, :tasks
  	rename_table :submission_definitions, :task_definitions
  	rename_table :submission_files, :task_files

  	rename_column :tasks, :submission_definition_id, :task_definition_id
  	rename_column :task_files, :submission_definition_id, :task_definition_id
  	rename_column :task_files, :submission_id, :task_id

  	add_column :task_definitions, :details, :text
  	add_column :task_definitions, :required, :boolean, default: false
  	add_column :task_definitions, :position, :integer
  	add_column :tasks, :state, :string, :after => :user_id
  	add_column :assignments, :state, :string, :after => :user_id
  	add_column :assignments, :completed_at, :datetime
  	add_column :assignments, :tasks_complete, :boolean, default: false

    change_column :task_definitions, :name, :text

  	add_index :task_definitions, :position
  	add_index :task_definitions, :required
  	add_index :tasks, :state
  	add_index :assignments, :state

  end

  def down

  	remove_index :assignments, :state
  	remove_index :tasks, :state
  	remove_index :task_definitions, :required
  	remove_index :task_definitions, :position

    change_column :task_definitions, :name, :string

  	remove_column :assignments, :tasks_complete
  	remove_column :assignments, :completed_at
  	remove_column :assignments, :state
  	remove_column :tasks, :state
  	remove_column :task_definitions, :position
  	remove_column :task_definitions, :required
  	remove_column :task_definitions, :details

  	rename_column :task_files, :task_id, :submission_id
  	rename_column :task_files, :task_definition_id, :submission_definition_id
  	rename_column :tasks, :task_definition_id, :submission_definition_id
  
  	rename_table :task_files, :submission_files
  	rename_table :task_definitions, :submission_definitions
  	rename_table :tasks, :submissions

  end
end
