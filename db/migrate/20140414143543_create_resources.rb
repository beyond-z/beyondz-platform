class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.string :url
      t.string :title
      t.text :note
      t.boolean :optional
      t.integer :resource_type

      t.timestamps
    end
  end
end
