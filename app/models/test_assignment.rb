class TestAssignment < ActiveRecord::Base

	has_many :files, class_name: 'AssignmentFile', :foreign_key => :assignment_id


	# blank out uploaded file data
	def reset_files
		files.each do |file|
			# if attachment type exists, delete it
			if file["#{file.file_type}_file_name"].present?
				file.update_attribute(file.file_type.to_sym, nil)
			end
		end
	end

end