class TaskSectionsAndModules < ActiveRecord::Migration
  def up
    
    create_table :task_sections do |t|
      t.integer :task_definition_id
      t.integer :task_module_id
      t.integer :position, null: false, default: 1
      t.text :content
      t.text :configuration
      t.timestamps
    end

    create_table :task_modules do |t|
      t.string :name
      t.string :code
      t.timestamps
    end

    create_table :task_responses do |t|
      t.integer :task_id
      t.integer :task_section_id
      t.text :answers
      t.timestamps
    end

    add_index :task_sections, :task_definition_id
    add_index :task_sections, :task_module_id
    add_index :task_responses, :task_id
    add_index :task_responses, :task_section_id 

    drop_table :task_texts

  end

  def down

    create_table :task_texts do |t|
      t.integer :task_id, null: false
      t.text :content, null: false
      t.timestamps
    end

    remove_index :task_responses, :task_section_id
    remove_index :task_responses, :task_id
    remove_index :task_sections, :task_module_id
    remove_index :task_sections, :task_definition_id

    drop_table :task_responses
    drop_table :task_modules
    drop_table :task_sections

  end
end
