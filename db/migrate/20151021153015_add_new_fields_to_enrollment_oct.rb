class AddNewFieldsToEnrollmentOct < ActiveRecord::Migration
  def change
    add_column :enrollments, :study_abroad, :boolean
    add_column :enrollments, :gender_identity, :string
  end
end
