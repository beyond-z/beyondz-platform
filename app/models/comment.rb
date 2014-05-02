class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  def self.for_student_attention(user_id)
    joins(:task)
      .where(:tasks => { :user_id => user_id, :state => "pending_revision"})
  end
end
