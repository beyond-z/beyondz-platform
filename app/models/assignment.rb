class Assignment < ActiveRecord::Base

	belongs_to :assignment_definition
	belongs_to :user
	has_many :tasks

	scope :complete, -> { all.reject{|a| a.tasks.incomplete.count > 0 } }
	scope :incomplete, -> { all.reject{|a| a.tasks.incomplete.count == 0 } }

end