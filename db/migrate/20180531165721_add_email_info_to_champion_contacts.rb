class AddEmailInfoToChampionContacts < ActiveRecord::Migration
  def change
    add_column :champion_contacts, :fellow_outreach_notice_sent, :boolean
  end
end
