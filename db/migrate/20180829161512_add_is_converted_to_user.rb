class AddIsConvertedToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_converted_on_salesforce, :boolean
  end
end
