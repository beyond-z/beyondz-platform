class UserAssignment < ActiveRecord::Base

	belongs_to :assignment
	belongs_to :user
	has_many :user_submissions

end