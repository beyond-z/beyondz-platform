class AddDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :applicant_details, :string
  end
end
