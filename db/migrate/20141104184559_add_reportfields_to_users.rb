class AddReportfieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :owner, :string
    add_column :users, :muted, :boolean
    add_column :users, :associated_program, :string
  end
end
