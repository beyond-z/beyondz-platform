class ChangeListContentToText < ActiveRecord::Migration
  def change
    change_column :lists, :content, :text
  end
end
