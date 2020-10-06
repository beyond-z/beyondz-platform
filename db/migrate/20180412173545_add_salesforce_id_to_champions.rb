class AddSalesforceIdToChampions < ActiveRecord::Migration
  def change
    add_column :champions, :salesforce_id, :string
  end
end
