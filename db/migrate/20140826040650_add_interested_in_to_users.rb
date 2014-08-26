class AddInterestedInToUsers < ActiveRecord::Migration
  def change
    add_column :users, :interested_joining, :boolean
    add_column :users, :interested_partnering, :boolean
    add_column :users, :interested_receiving, :boolean
  end
end
