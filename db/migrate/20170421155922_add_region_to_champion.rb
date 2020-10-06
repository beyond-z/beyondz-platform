class AddRegionToChampion < ActiveRecord::Migration
  def change
    add_column :champions, :region, :string
  end
end
