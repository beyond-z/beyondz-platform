class AddUniversityNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :university_name, :string
  end
end
