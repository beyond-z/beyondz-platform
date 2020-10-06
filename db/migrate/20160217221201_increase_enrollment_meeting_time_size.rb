class IncreaseEnrollmentMeetingTimeSize < ActiveRecord::Migration
  def change
    change_column :enrollments, :meeting_times, :text
  end
end
