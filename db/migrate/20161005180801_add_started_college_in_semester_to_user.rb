class AddStartedCollegeInSemesterToUser < ActiveRecord::Migration
  def change
    add_column :users, :started_college_in_semester, :string
  end
end
