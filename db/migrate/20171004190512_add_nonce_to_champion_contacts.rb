class AddNonceToChampionContacts < ActiveRecord::Migration
  def change
    add_column :champion_contacts, :nonce, :string
  end
end
