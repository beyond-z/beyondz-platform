class AddEmailInfoToChampion < ActiveRecord::Migration
  def change
    add_column :champions, :flood_notice_last_emailed, :datetime
    add_column :champions, :unresponsive_indicated_at, :datetime
  end
end
