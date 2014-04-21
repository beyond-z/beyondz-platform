class UserSubmission < ActiveRecord::Base

	belongs_to :user_assignment
	belongs_to :submission
	belongs_to :user
	has_many :files, class_name: 'UserSubmissionFile'

	scope :for_assignment, ->(user_assignment_id) { where(user_assignment_id: user_assignment_id)}
end