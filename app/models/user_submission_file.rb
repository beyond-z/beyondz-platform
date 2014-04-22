class UserSubmissionFile < ActiveRecord::Base

	belongs_to :submission
	belongs_to :user_submission

	has_attached_file :document
	do_not_validate_attachment_file_type :document
	validates_attachment :document,
  	:size => { :in => 0..1.megabytes
  }

  has_attached_file :image
	do_not_validate_attachment_file_type :image
	validates_attachment :image,
  	:content_type => { :content_type => "image/jpg" },
  	:size => { :in => 0..1.megabytes
  }

  has_attached_file :video
	do_not_validate_attachment_file_type :video
	validates_attachment :video,
  	:size => { :in => 0..1.megabytes
  }

  has_attached_file :audio
	do_not_validate_attachment_file_type :audio
	validates_attachment :audio,
  	:size => { :in => 0..1.megabytes
  }

	
	default_scope {order('created_at ASC')}


end