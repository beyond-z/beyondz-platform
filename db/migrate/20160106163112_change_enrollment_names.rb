class ChangeEnrollmentNames < ActiveRecord::Migration
  def change
    rename_column :enrollments, :current_volunteer_activities, :other_commitments
    rename_column :enrollments, :personal_passion, :passions_expertise
    rename_column :enrollments, :meaningful_experience, :meaningful_activity
    rename_column :enrollments, :teaching_experience, :relevant_experience
    rename_column :enrollments, :university, :undergrad_university
    rename_column :enrollments, :anticipated_graduation, :undergraduate_year
    rename_column :enrollments, :lead_sources, :sourcing_info
    rename_column :enrollments, :online_resume, :digital_footprint
    rename_column :enrollments, :online_resume2, :digital_footprint2
  end
end
