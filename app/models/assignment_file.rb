class AssignmentFile < ActiveRecord::Base

	has_attached_file :document
	do_not_validate_attachment_file_type :document
	validates_attachment :document,
		#:presence => true,
  	#:content_type => { :content_type => "image/jpg" },
  	:size => { :in => 0..1.megabytes
  }

	belongs_to :assignment, class_name: 'TestAssignment', :foreign_key => :assignment_id


	default_scope {order('created_at ASC')}


end