class AddFinishedUrlToAssignmentDefinition < ActiveRecord::Migration
  def change
    add_column :assignment_definitions, :finished_url, :string
  end
end
