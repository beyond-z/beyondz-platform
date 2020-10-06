class AddEnableApplyNowToUsers < ActiveRecord::Migration
  def change
    add_column :users, :apply_now_enabled, :boolean
  end
end
