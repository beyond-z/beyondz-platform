class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  # This returns comments that needs the student's attention,
  # currently meaning those from a coach on one of this student's
  # tasks that is pending revision.
  def self.needs_student_attention(student_id)
    joins(:task)
      .where(:tasks => { :user_id => student_id, :state => "pending_revision"})
  end
end
