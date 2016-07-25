class AddSemesterToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :anticipated_graduation_semester, :string
  end
end
