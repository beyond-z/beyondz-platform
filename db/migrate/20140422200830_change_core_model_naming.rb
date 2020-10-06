class ChangeCoreModelNaming < ActiveRecord::Migration
  def up
  	
  	rename_table :assignments, :assignment_definitions
  	rename_table :submissions, :submission_definitions
  	rename_table :user_submission_files, :submission_files
  	rename_table :todos, :todo_definitions
  	rename_table :user_assignments, :assignments
  	rename_table :user_submissions, :submissions
  	rename_table :user_todos, :todos

  	rename_column :assignments, :assignment_id, :assignment_definition_id
  	rename_column :submissions, :user_assignment_id, :assignment_id
  	rename_column :submissions, :submission_id, :submission_definition_id
  	rename_column :submission_definitions, :assignment_id, :assignment_definition_id
  	rename_column :submission_files, :submission_id, :submission_definition_id
  	rename_column :submission_files, :user_submission_id, :submission_id
  	rename_column	:todos, :todo_id, :todo_definition_id
  	rename_column :todo_definitions, :assignment_id, :assignment_definition_id

    add_column :todos, :assignment_id, :integer

  end

  def down

    remove_column :todos, :assignment_id

  	rename_column :todo_definitions, :assignment_definition_id, :assignment_id
  	rename_column	:todos, :todo_definition_id, :todo_id
  	rename_column :submission_files, :submission_id, :user_submission_id
  	rename_column :submission_files, :submission_definition_id, :submission_id
  	rename_column :submission_definitions, :assignment_definition_id, :assignment_id
  	rename_column :submissions, :submission_definition_id, :submission_id
  	rename_column :submissions, :assignment_id, :user_assignment_id
  	rename_column :assignments, :assignment_definition_id, :assignment_id

  	rename_table :todos, :user_todos
  	rename_table :submissions, :user_submissions
  	rename_table :assignments, :user_assignments
  	rename_table :todo_definitions, :todos
  	rename_table :submission_files, :user_submission_files
  	rename_table :submission_definitions, :submissions
  	rename_table :assignment_definitions, :assignments

  end
end