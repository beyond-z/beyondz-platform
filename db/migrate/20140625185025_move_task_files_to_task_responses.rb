class MoveTaskFilesToTaskResponses < ActiveRecord::Migration
  
  def up
    remove_column :task_definitions, :file_type
    add_column :task_sections, :file_type, :integer
    remove_column :tasks, :file_type
    add_column :task_responses, :file_type, :integer
    remove_column :task_files, :task_definition_id
    add_column :task_files, :task_section_id, :integer
    remove_column :task_files, :task_id
    add_column :task_files, :task_response_id, :integer

    add_index :task_files, :task_section_id
    add_index :task_files, :task_response_id
  end

  def down
    remove_index :task_files, :task_response_id
    remove_index :task_files, :task_section_id

    remove_column :task_files, :task_response_id
    add_column :task_files, :task_id, :integer
    remove_column :task_files, :task_section_id
    add_column :task_files, :task_definition_id, :integer
    remove_column :task_responses, :file_type
    add_column :tasks, :file_type, :integer
    remove_column :task_sections, :file_type
    add_column :task_definitions, :file_type, :integer
  end

end
