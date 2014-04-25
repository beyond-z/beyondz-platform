class Pupil < ActiveRecord::Base
  belongs_to :coach, :foreign_key => "user_id", :class_name => "User"
  belongs_to :user, :foreign_key => "pupil_id", :class_name => "User"
end
