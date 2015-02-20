class CreateApplications < ActiveRecord::Migration
  def change
    create_table :applications do |t|
      t.boolean :active
      t.string :associated_campaign

      t.timestamps
    end
  end
end
