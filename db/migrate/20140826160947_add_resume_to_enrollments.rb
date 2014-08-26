class AddResumeToEnrollments < ActiveRecord::Migration
  def change
    remove_column :enrollments, :resume, :string
    add_attachment :enrollments, :resume
  end
end
