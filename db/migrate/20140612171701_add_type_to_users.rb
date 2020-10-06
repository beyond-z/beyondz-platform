class AddTypeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :applicant_type, :string
  end
end
