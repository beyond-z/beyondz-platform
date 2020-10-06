class AddJobTitleToChampion < ActiveRecord::Migration
  def change
    add_column :champions, :job_title, :string
  end
end
