class AddSignupFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :started_college_in, :integer
    add_column :users, :like_to_know_when_program_starts, :boolean
    add_column :users, :like_to_help_set_up_program, :boolean
    add_column :users, :profession, :string
    add_column :users, :company, :string
    add_column :users, :bz_region, :string
    add_column :users, :applicant_comments, :text
  end
end
