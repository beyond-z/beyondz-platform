class AddSignupFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :started_college_in, :integer
    add_column :users, :like_to_know_when_program_starts, :boolean
    add_column :users, :like_to_help_set_up_program, :boolean
    add_column :users, :profession, :string
    add_column :users, :company, :string
    add_column :users, :sf_east_bay, :boolean
    add_column :users, :sf_san_jose, :boolean
    add_column :users, :nyc_area, :boolean
    add_column :users, :dc_area, :boolean
  end
end
