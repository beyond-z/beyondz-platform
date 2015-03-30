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

  validates :university, presence: true
  validates :why_bz, presence: true, if: "position == 'coach'"
  validates :personal_passion, presence: true, if: "position == 'coach'"
  validates :meaningful_experience, presence: true, if: "position == 'coach'"
  validates :teaching_experience, presence: true, if: "position == 'coach'"

  validates :current_volunteer_activities, presence: true, if: "position == 'student'"
  validates :last_summer, presence: true, if: "position == 'student'"
  validates :post_graduation_plans, presence: true, if: "position == 'student'"
  validates :why_bz, presence: true, if: "position == 'student'"
  validates :community_connection, presence: true, if: "position == 'student'"
  validates :meaningful_experience, presence: true, if: "position == 'student'"
  validates :affirm_qualified, presence: true, if: "position == 'student'"
  validates :affirm_commit, presence: true, if: "position == 'student'"
  validates :will_be_student, presence: true, if: "position == 'student'"

  validates :program_col, presence: true

  validates :reference_name, presence: true
  validates :reference2_name, presence: true

  # This gets the salesforce campaign ID associated with this
  # enrollment form so we can tie back into that from a submitted
  # enrollment.
  #
  # As we do more campaigns with more specific applications, like
  # adding regions, this needs to be updated too so everything matches
  # both ways.
  def associated_campaign
    app = Application.where(:form => position)
    if app.empty?
      return nil
    else
      app.first.associated_campaign
    end
  end
end
