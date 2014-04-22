class UserSubmission < ActiveRecord::Base

	belongs_to :user_assignment
	belongs_to :submission
	belongs_to :user
	has_many :files, class_name: 'UserSubmissionFile'

	scope :for_assignment, ->(user_assignment_id) { where(user_assignment_id: user_assignment_id)}

	# blank out uploaded file data
	def reset_files
		files.each do |file|
			# if attachment type exists, delete it
			if file["#{file_type}_file_name"].present?
				file.update_attribute(file_type.to_sym, nil)
			end
		end
	end
end