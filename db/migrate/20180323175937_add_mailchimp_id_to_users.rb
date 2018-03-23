class AddMailchimpIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mailchimp_id, :string
  end
end
