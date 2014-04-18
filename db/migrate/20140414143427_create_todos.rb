class CreateTodos < ActiveRecord::Migration
  def change
    create_table :todos do |t|
      t.references :assignment, index: true
      t.text :content
      t.integer :ordering

      t.timestamps
    end
  end
end
