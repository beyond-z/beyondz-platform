class Enrollment < ActiveRecord::Base
  belongs_to :user

  has_attached_file :resume
  validates_attachment :resume,
                       content_type: {
                         content_type: [
                           'application/pdf',
                           'application/msword',
                           'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                         ],
                         message: 'is invalid: please upload either a .doc or a .pdf file'
                       },
                       size: {
                         in: 0..2.megabytes,
                         # If you change this size, don't forget to change
                         # enrollment/_form.html.erb too so the user sees it there
                         message: 'is too large: please upload files no larger than 2 MB'
                       }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :phone, presence: true

  validates :city, presence: true
  validates :state, presence: true

  validates :birthdate, presence: true, if: "position == 'student'"
  # validates :last_summer, presence: true, if: "position == 'student'"
  validates :meaningful_activity, presence: true, if: "position == 'student' || position == 'coach'"

  validates :why_bz, presence: true, if: "position == 'coach'"
  validates :passions_expertise, presence: true, if: "position == 'coach'"
  validates :relevant_experience, presence: true, if: "position == 'coach'"

  validates :affirm_commit_coach, presence: true, if: "position == 'coach'"

  validates :other_commitments, presence: true, if: "position == 'student'"
  validates :post_graduation_plans, presence: true, if: "position == 'student'"
  validates :why_bz, presence: true, if: "position == 'student'"
  validates :affirm_qualified, presence: true, if: "position == 'student'"
  validates :affirm_commit, presence: true, if: "position == 'student'"
  validates :will_be_student, presence: true, if: "position == 'student'"
  validates :undergraduate_year, presence: true, if: "position == 'student'"

  validates :reference_name, presence: true, if: "position == 'coach'"
  validates :reference_email, presence: true, if: "position == 'coach' && reference_phone.empty?"
  validates :reference2_name, presence: true, if: "position == 'coach'"
  validates :reference2_email, presence: true, if: "position == 'coach' && reference2_phone.empty?"

  validates :industry, presence: true, if: "position == 'coach' && company.empty? && title.empty?"

  validates :meeting_times, presence: true, if: '@check_meeting_times'

  attr_writer :check_meeting_times

  before_save :capitalize_name
  def capitalize_name
    self.first_name = first_name.split.map(&:capitalize).join(' ') unless first_name.nil?
    self.last_name = last_name.split.map(&:capitalize).join(' ') unless last_name.nil?
  end

  before_save :strip_birthdate
  def strip_birthdate
    self.birthdate = birthdate.strip unless birthdate.nil?
  end

  before_save :set_gpa_if_zero
  def set_gpa_if_zero
    self.gpa = 'NA' if gpa.blank? || gpa == '0'
  end

  def self.latest_for_user(user_id)
    enrollments = Enrollment.where(:user_id => user_id).order(updated_at: :desc)
    enrollment = enrollments.empty? ? nil : enrollments.first
    enrollment
  end
end
