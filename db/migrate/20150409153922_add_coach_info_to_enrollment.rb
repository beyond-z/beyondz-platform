class AddCoachInfoToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :industry, :string
    add_column :enrollments, :company, :string
    add_column :enrollments, :title, :string
    add_column :enrollments, :affirm_commit_coach, :boolean
  end
end
