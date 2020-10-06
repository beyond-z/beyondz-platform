class AddExplcitlySubmittedToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :explicitly_submitted, :boolean
  end
end
