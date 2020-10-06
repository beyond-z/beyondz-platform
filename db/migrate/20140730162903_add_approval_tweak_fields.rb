class AddApprovalTweakFields < ActiveRecord::Migration
  def up
    remove_column :task_definitions, :kind
    remove_column :tasks, :kind

    add_column :assignments, :submitted_at, :datetime
    add_column :tasks, :submitted_at, :datetime
  end

  def down
    remove_column :tasks, :submitted_at
    remove_column :assignments, :submitted_at

    add_column :tasks, :kind, :integer, default: 0
    add_column :task_definitions, :kind, :integer, default: 0
  end
end
