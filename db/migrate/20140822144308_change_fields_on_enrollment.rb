class ChangeFieldsOnEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :other_meaningful_volunteer_activities, :text
    add_column :enrollments, :current_volunteer_activities, :text
    add_column :enrollments, :meaningful_experience, :text
    add_column :enrollments, :languages, :string

    # per Sheila and Abby, we just want NYC right now, not specific boroughs

    add_column :enrollments, :program_ms_ms_nyc, :boolean
    #add_column :enrollments, :program_ms_ms_brx, :boolean
    remove_column :enrollments, :program_ms_ms_brk, :boolean
    remove_column :enrollments, :program_ms_ms_rlm, :boolean

    # DC is not yet live
    #add_column :enrollments, :program_ms_ms_dc, :boolean

    add_column :enrollments, :program_ms_ms_mp, :boolean

    add_column :enrollments, :grad_school, :string
    add_column :enrollments, :grad_degree, :string
    add_column :enrollments, :anticipated_grad_school_graduation, :string

    remove_column :enrollments, :community_organization_commitment, :text
    remove_column :enrollments, :academic_work_since_undergrad, :text
  end
end
