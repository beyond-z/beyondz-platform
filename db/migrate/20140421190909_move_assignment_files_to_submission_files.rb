class MoveAssignmentFilesToSubmissionFiles < ActiveRecord::Migration
  def up

  	create_table :user_assignments do |t|
    	t.integer :assignment_id
  		t.integer :user_id
    	t.timestamps
    end

  	create_table :submissions do |t|
  		t.integer :assignment_id
  		t.string :name
  		t.string :kind
  		t.string :file_type
    	t.timestamps
    end

    create_table :user_submissions do |t|
    	t.integer :user_assignment_id
  		t.integer :submission_id
  		t.integer :user_id
  		t.string :kind
  		t.string :file_type
    	t.timestamps
    end

    create_table :user_submission_files do |t|
    	t.integer :submission_id
    	t.integer :user_submission_id
    	t.timestamps
    end

   	add_attachment :user_submission_files, :image
   	add_attachment :user_submission_files, :document
   	add_attachment :user_submission_files, :video
   	add_attachment :user_submission_files, :audio

   	add_index :user_assignments, :assignment_id
   	add_index :user_assignments, :user_id
   	add_index :submissions, :assignment_id
   	add_index :user_submissions, :user_assignment_id
   	add_index :user_submissions, :submission_id
   	add_index :user_submissions, :user_id
   	add_index :user_submission_files, :submission_id
   	add_index :user_submission_files, :user_submission_id

  end

  def down

  	remove_index :user_submission_files, :user_submission_id
  	remove_index :user_submission_files, :submission_id
  	remove_index :user_submissions, :user_id
  	remove_index :user_submissions, :submission_id
  	remove_index :user_submissions, :user_assignment_id
  	remove_index :submissions, :assignment_id
  	remove_index :user_assignments, :user_id
  	remove_index :user_assignments, :assignment_id

  	remove_attachment :user_submission_files, :image
   	remove_attachment :user_submission_files, :document
   	remove_attachment :user_submission_files, :video
   	remove_attachment :user_submission_files, :audio

  	drop_table :user_submission_files
  	drop_table :user_submissions
  	drop_table :submissions
  	drop_table :user_assignments
  
  end
end
