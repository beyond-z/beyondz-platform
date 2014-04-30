class CoachStudent < ActiveRecord::Base
  belongs_to :coach, :foreign_key => "coach_id", :class_name => "User"
  belongs_to :student, :foreign_key => "student_id", :class_name => "User"
end
