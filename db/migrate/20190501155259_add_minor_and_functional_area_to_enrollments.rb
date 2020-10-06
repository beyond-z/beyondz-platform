class AddMinorAndFunctionalAreaToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :minor, :string
    add_column :enrollments, :functional_area, :string
  end
end
