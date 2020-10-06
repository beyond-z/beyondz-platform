class AddCollegeEnrollmentInfoToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :enrollment_year, :integer
    add_column :enrollments, :enrollment_semester, :string
  end
end
