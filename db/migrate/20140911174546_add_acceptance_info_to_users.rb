class AddAcceptanceInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :accepted_into_program, :boolean
    add_column :users, :declined_from_program, :boolean
    add_column :users, :fast_tracked, :boolean
    add_column :users, :program_attendance_confirmed, :boolean
    add_column :users, :interview_scheduled, :boolean
    add_column :users, :availability_confirmation_requested, :boolean
  end
end
