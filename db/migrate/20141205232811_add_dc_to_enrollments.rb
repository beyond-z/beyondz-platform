class AddDcToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :program_ms_ms_dc, :boolean
  end
end
