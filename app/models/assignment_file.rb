class AssignmentFile < ActiveRecord::Base

	belongs_to :assignment, class_name: 'TestAssignment', :foreign_key => :assignment_id

end