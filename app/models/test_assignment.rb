class TestAssignment < ActiveRecord::Base

	has_many :files, class_name: 'AssignmentFile', :foreign_key => :assignment_id

end