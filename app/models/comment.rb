class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  enum file_type: { document: 0, image: 1, video: 2, audio: 3 }

  has_attached_file :document
  validates_attachment :document,
    :content_type => {
      :content_type => [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      ]
    },
    :size => { :in => 0..2.megabytes }

  has_attached_file :image
  validates_attachment :image,
    :styles => { :thumb => '100x100>' },
    content_type: {
      content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif']
    },
    size: { in: 0..2.megabytes }

  has_attached_file :video
  validates_attachment :video,
    content_type: {
      content_type: ['video/quicktime', 'video/mpeg', 'video/avi']
    },
    size: { in: 0..2.megabytes }

  has_attached_file :audio
  validates_attachment :audio,
    :content_type => { :content_type => ['audio/mp3', 'application/x-mp3'] },
    :size => { :in => 0..2.megabytes }


  default_scope { order('created_at ASC') }
  scope :needs_student_attention, -> (student_id) {
    joins(:task)\
    .where(tasks: { user_id: student_id, :state => :pending_revision})
  }


  def has_attachment?
    !file_type.nil?
  end

  def attachment_url(style=nil)
    # dynamically determine the file url for the given type
    eval_string = "#{file_type}.url"
    if style
      eval_string += "(:#{style})"
    end
Rails.logger.info eval_string
    eval eval_string
  end

  def attachment_name
    # dynamically determine the file url for the given type
    eval "#{file_type}_file_name"
  end

  def reset
    update_attribute(file_type.to_sym, nil)
  end

end
