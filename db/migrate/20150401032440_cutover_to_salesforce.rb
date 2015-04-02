class CutoverToSalesforce < ActiveRecord::Migration
  def change
    drop_table :applications do |t|
      t.boolean :active
      t.string :associated_campaign
      t.string :form

      t.timestamps
    end

    add_column :enrollments, :campaign_id, :string
  end
end
