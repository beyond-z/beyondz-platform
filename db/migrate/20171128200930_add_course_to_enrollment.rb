class AddCourseToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :student_course, :string
  end
end
