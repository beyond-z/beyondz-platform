class TestAssignment < ActiveRecord::Base

	has_many :files, class_name: 'AssignmentFile', :foreign_key => :assignment_id


	# blank out uploaded file data and delete the file itself
	def reset_files
		files.each do |file|
			type = file.file_type
			file.update_attributes("#{type}_file_name" => nil, "#{type}_content_type" => nil, "#{type}_file_size" => nil, "#{type}_updated_at" => nil)
		end

		# also delete file
	end

end