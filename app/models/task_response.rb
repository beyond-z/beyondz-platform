class TaskResponse < ActiveRecord::Base

  belongs_to :task
  belongs_to :task_section
  has_many :files, class_name: 'TaskFile', dependent: :destroy

  enum file_type: { document: 0, image: 1, video: 2, audio: 3 }

  scope :for_section, -> (task_section_id) {
    find_by_task_section_id(task_section_id)
  }


  # blank out uploaded file data
  def reset_files
    files.each do |file|
      # if attachment type exists, delete it
      if type_exists?(file_type)
        file.reset(file_type)
      end
    end
  end

  def delete_files
    files.each do |file|
      file.reset(file_type)
      file.destroy
    end
  end

end