class AddTokenToChampions < ActiveRecord::Migration
  def change
    add_column :champions, :access_token, :string
  end
end
