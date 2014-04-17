class TestAssignment < ActiveRecord::Base

	has_many :files, class_name: 'AssignmentFile', :foreign_key => :assignment_id


	# blank out uploaded file data and delete the file itself
	def reset_files
		files.each do |file|
			file_attribute = "file.#{file.file_type}"
			eval "file_attribute = nil"
			file.save
		end

		# also delete file
	end

end