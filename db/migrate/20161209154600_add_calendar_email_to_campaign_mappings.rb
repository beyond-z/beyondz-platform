class AddCalendarEmailToCampaignMappings < ActiveRecord::Migration
  def change
    add_column :campaign_mappings, :calendar_email, :string
    add_column :campaign_mappings, :calendar_url, :string
  end
end
