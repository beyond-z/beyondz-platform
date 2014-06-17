class AddInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :keep_updated, :boolean
    add_column :users, :anticipated_graduation, :string
  end
end
