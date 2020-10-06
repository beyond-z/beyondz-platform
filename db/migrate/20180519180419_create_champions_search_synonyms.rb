class CreateChampionsSearchSynonyms < ActiveRecord::Migration
  def change
    create_table :champions_search_synonyms do |t|
      t.string :search_term
      t.string :search_becomes

      t.index :search_term

      t.timestamps
    end
  end
end
