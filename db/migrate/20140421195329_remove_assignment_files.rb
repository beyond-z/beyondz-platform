class RemoveAssignmentFiles < ActiveRecord::Migration
  def change
  	drop_table :assignment_files
  end
end
