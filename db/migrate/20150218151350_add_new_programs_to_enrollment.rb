class AddNewProgramsToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :program_col_col_dc, :boolean
    add_column :enrollments, :program_col_col_nyc, :boolean
  end
end
