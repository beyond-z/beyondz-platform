class CreateAssignmentFiles < ActiveRecord::Migration
  def up
    create_table :assignment_files do |t|
    	t.integer :assignment_id
    	t.string :file_type
    	t.timestamps
    end

   	add_attachment :assignment_files, :image
   	add_attachment :assignment_files, :document
   	add_attachment :assignment_files, :video
   	add_attachment :assignment_files, :audio
    
  end

  def down

  	remove_attachment :assignment_files, :image
   	remove_attachment :assignment_files, :document
   	remove_attachment :assignment_files, :video
   	remove_attachment :assignment_files, :audio

  	drop_table :assignment_files
  end
end
