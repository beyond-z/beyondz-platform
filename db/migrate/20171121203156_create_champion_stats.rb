class CreateChampionStats < ActiveRecord::Migration
  def change
    create_table :champion_stats do |t|
      t.string :search_term
      t.integer :search_count

      t.timestamps
    end
  end
end
