# This encodes the student<->coach relationship.
#
# Both coaches and students are Users who simply have
# a many-to-many relationship between them; one coach
# may have multiple students and one student may have
# multiple coaches.
#
# This class should be invisible to the api consumer
# and only serves to join the two users together in
# this relationship.
class CoachStudent < ActiveRecord::Base
  belongs_to :coach, :foreign_key => "coach_id", :class_name => "User"
  belongs_to :student, :foreign_key => "student_id", :class_name => "User"
end
