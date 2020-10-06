class AddNewFieldsToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :city, :string
    add_column :enrollments, :state, :string
    add_column :enrollments, :student_id, :string
    add_column :enrollments, :hs_gpa, :string
    add_column :enrollments, :sat_score, :string
    add_column :enrollments, :act_score, :string
    add_column :enrollments, :online_resume2, :string
    add_column :enrollments, :conquered_challenge, :text
    add_column :enrollments, :bkg_other, :string
    add_column :enrollments, :lead_sources, :string
    add_column :enrollments, :pell_grant, :boolean
    add_column :enrollments, :meeting_times, :string
  end
end
