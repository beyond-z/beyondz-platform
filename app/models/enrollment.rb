class Enrollment < ActiveRecord::Base

  belongs_to :user

  has_attached_file :resume
  validates_attachment :resume,
                       content_type: {
                         content_type: [
                           'application/pdf',
                           'application/msword',
                           'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                         ]
                       },
                       size: { in: 0..2.megabytes }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :phone, presence: true

  validates :city, presence: true
  validates :state, presence: true

  validates :birthdate, presence: true, if: "position == 'student'"
  validates :gpa, presence: true, if: "position == 'student'"
  validates :online_resume, presence: true
  validates :online_resume2, presence: true, if: "position == 'coach'"
  validates :conquered_challenge, presence: true, if: "position == 'student'"
  validates :last_summer, presence: true, if: "position == 'student'"
  validates :meaningful_experience, presence: true

  validates :university, presence: true
  validates :why_bz, presence: true, if: "position == 'coach'"
  validates :personal_passion, presence: true, if: "position == 'coach'"
  validates :teaching_experience, presence: true, if: "position == 'coach'"

  validates :current_volunteer_activities, presence: true, if: "position == 'student'"
  validates :post_graduation_plans, presence: true, if: "position == 'student'"
  validates :why_bz, presence: true, if: "position == 'student'"
  validates :affirm_qualified, presence: true, if: "position == 'student'"
  validates :affirm_commit, presence: true, if: "position == 'student'"
  validates :will_be_student, presence: true, if: "position == 'student'"

  validates :reference_name, presence: true, if: "position == 'coach'"
  validates :reference_email, presence: true, if: "position == 'coach'"
  validates :reference2_name, presence: true, if: "position == 'coach'"
  validates :reference2_email, presence: true, if: "position == 'coach'"
end
