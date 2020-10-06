class AddEmailTimesToChampionContact < ActiveRecord::Migration
  def change
    add_column :champion_contacts, :first_email_from_fellow_sent, :datetime
    add_column :champion_contacts, :latest_email_from_fellow_sent, :datetime
    add_column :champion_contacts, :first_email_from_champion_sent, :datetime
    add_column :champion_contacts, :latest_email_from_champion_sent, :datetime
  end
end
