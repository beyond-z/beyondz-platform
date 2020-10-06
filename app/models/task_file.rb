class TaskFile < ActiveRecord::Base
  belongs_to :task_section
  belongs_to :task_response

  has_attached_file :document
  validates_attachment :document,
                       content_type: {
                         content_type: [
                           'application/pdf',
                           'application/msword',
                           'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                         ]
                       },
                       size: { in: 0..2.megabytes }

  has_attached_file :image
  validates_attachment :image,
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
                       content_type: { content_type: ['audio/mp3', 'application/x-mp3'] },
                       size: { in: 0..2.megabytes }


  default_scope { order('created_at ASC') }


  def url
    # dynamically determine the file url for the given type
    eval "#{task_response.file_type}.url"
  end

  def type_exists?(file_type)
    self["#{file_type}_file_name"].present?
  end

  def name
    self["#{task_response.file_type}_file_name"]
  end

  def reset(file_type)
    update_attribute(file_type.to_sym, nil)
  end
end