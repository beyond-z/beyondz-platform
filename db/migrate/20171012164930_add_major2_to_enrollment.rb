class AddMajor2ToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :major2, :string
  end
end
