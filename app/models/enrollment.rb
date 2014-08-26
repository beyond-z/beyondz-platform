class Enrollment < ActiveRecord::Base

  belongs_to :user

  has_attached_file :resume
  validates_attachment :resume,
                       content_type: {
                         content_type: [
                           'application/pdf',
                           'application/msword',
                           'application/vnd.openxmlformats-officedocument.wordpr
ocessingml.document'
                         ]
                       },
                       size: { in: 0..2.megabytes }
end
