class RemoveTestAssignments < ActiveRecord::Migration
  def change
  	drop_table :test_assignments
  end
end
