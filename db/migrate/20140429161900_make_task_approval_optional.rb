class MakeTaskApprovalOptional < ActiveRecord::Migration
  def up
    add_column :task_definitions, :requires_approval, :boolean, :default => false
  end

  def down
    remove_column :task_definitions, :requires_approval
  end
end
