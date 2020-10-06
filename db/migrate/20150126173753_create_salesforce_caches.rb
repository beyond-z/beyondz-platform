class CreateSalesforceCaches < ActiveRecord::Migration
  def change
    create_table :salesforce_caches do |t|
      t.string :key
      t.text :value

      t.timestamps
    end
  end
end
