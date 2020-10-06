class AddBirthdateToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :birthdate, :string
  end
end
