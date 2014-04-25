class Task < ActiveRecord::Base

	belongs_to :assignment
	belongs_to :task_definition
	belongs_to :user
	has_many :files, class_name: 'TaskFile'

	default_scope order('position ASC')
	scope :for_assignment, -> (assignment_id) { where(assignment_id: assignment_id) }
	scope :complete, -> { where({state: 'complete'}) }
  scope :incomplete, -> { where.not({state: 'complete'}) }

	# blank out uploaded file data
	def reset_files
		files.each do |file|
			# if attachment type exists, delete it
			if type_exists?(file_type)
				file.reset(file_type)
			end
		end
	end

	def delete_files
		files.each do |file|
			file.reset(file_type)
			file.destroy
		end
	end
end