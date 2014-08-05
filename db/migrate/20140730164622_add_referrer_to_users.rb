class AddReferrerToUsers < ActiveRecord::Migration
  def change
    add_column :users, :external_referral_url, :string
    add_column :users, :internal_referral_url, :string
  end
end
