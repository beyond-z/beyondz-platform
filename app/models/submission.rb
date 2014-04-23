class Submission < ActiveRecord::Base

	belongs_to :assignment
	belongs_to :submission_definition
	belongs_to :user
	has_many :files, class_name: 'SubmissionFile'

	#accepts_nested_attributes_for :files

	scope :for_assignment, ->(assignment_id) { where(assignment_id: assignment_id)}

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