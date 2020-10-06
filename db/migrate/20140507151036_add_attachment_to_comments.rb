class AddAttachmentToComments < ActiveRecord::Migration
  def up
    add_column :comments, :file_type, :integer

    add_attachment :comments, :image
    add_attachment :comments, :document
    add_attachment :comments, :video
    add_attachment :comments, :audio
  end

  def down
    remove_attachment :comments, :image
    remove_attachment :comments, :document
    remove_attachment :comments, :video
    remove_attachment :comments, :audio

    remove_column :comments, :file_type
  end
end
