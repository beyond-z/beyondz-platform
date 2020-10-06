class AddResetInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :reset_token, :string
    add_column :users, :reset_expiration, :datetime
  end
end
