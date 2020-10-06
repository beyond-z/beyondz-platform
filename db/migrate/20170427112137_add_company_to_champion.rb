class AddCompanyToChampion < ActiveRecord::Migration
  def change
    add_column :champions, :company, :string
  end
end
