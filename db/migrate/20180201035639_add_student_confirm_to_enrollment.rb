class AddStudentConfirmToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :student_confirmed, :string
    add_column :enrollments, :student_confirmed_notes, :text
  end
end
