class AddIsGraduateStudentToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :is_graduate_student, :boolean
  end
end
