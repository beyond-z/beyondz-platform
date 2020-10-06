class CreateTaskTexts < ActiveRecord::Migration
  def up

    create_table :task_texts do |t|
      t.integer :task_id, null: false
      t.text :content, null: false
      t.timestamps
    end
  
    add_index :task_texts, :task_id

  end

  def down
  
    #remove_index :task_texts, :task_id

    drop_table :task_texts
  
  end
end
