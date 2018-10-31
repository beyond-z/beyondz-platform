class AddRegistrationStatusToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :registration_status, :string
  end
end
