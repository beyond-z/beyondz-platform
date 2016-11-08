class ChangeDigitalFootprintFormatInEnrollment < ActiveRecord::Migration
  def change
    change_column(:enrollments, :digital_footprint, :text)
    change_column(:enrollments, :digital_footprint2, :text)
  end
end
