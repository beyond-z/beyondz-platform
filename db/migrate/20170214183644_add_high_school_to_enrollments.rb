class AddHighSchoolToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :high_school, :text
  end
end
