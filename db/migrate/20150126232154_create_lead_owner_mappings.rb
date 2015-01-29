class CreateLeadOwnerMappings < ActiveRecord::Migration
  def change
    create_table :lead_owner_mappings do |t|
      t.string :lead_owner
      t.string :applicant_type
      t.string :state
      t.boolean :interested_joining

      t.timestamps
    end
  end
end
