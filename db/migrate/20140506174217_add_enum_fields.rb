class AddEnumFields < ActiveRecord::Migration
  def up
    remove_column :task_definitions, :kind
    add_column :task_definitions, :kind, :integer, default: 0
    remove_column :task_definitions, :file_type
    add_column :task_definitions, :file_type, :integer

    remove_column :tasks, :kind
    add_column :tasks, :kind, :integer, default: 0
    remove_column :tasks, :file_type
    add_column :tasks, :file_type, :integer
  end

  def down
    remove_column :tasks, :file_type
    add_column :tasks, :file_type, :string
    remove_column :tasks, :kind
    add_column :tasks, :kind, :string

    remove_column :task_definitions, :file_type
    add_column :task_definitions, :file_type, :string
    remove_column :task_definitions, :kind
    add_column :task_definitions, :kind, :string
  end
end
