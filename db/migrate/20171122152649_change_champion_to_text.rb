class ChangeChampionToText < ActiveRecord::Migration
  def change
    change_column :champions, :access_token, :text
  end
end
