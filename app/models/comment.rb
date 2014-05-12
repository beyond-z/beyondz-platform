class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  # This returns comments that needs the student's attention,
  # currently meaning those from a coach on one of this student's
  # tasks that is pending revision.
  def self.needs_student_attention(student_id, assignment_id = nil)
    condition = { :user_id => student_id, :state => "pending_revision"}
    if assignment_id
      condition[:assignment_id] = assignment_id
    end

    joins(:task)
      .where(:tasks => condition)
      .where.not(:user_id => student_id)
  end
end
