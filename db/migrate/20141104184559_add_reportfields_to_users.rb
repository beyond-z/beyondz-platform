class AddReportfieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :relationship_manager, :string
    add_column :users, :exclude_from_reporting, :boolean
    add_column :users, :associated_program, :string
  end
end
