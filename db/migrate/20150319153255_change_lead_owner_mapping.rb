class ChangeLeadOwnerMapping < ActiveRecord::Migration
  def change
    add_column :lead_owner_mappings, :university_name, :string
    add_column :lead_owner_mappings, :bz_region, :string

    remove_column :lead_owner_mappings, :state, :string
    remove_column :lead_owner_mappings, :interested_joining, :boolean
  end
end
