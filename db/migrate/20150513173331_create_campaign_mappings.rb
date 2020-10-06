class CreateCampaignMappings < ActiveRecord::Migration
  def change
    create_table :campaign_mappings do |t|
      t.string :campaign_id
      t.string :applicant_type
      t.string :university_name
      t.string :bz_region

      t.timestamps
    end
  end
end
