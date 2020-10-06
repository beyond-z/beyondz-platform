include Paperclip::Schema
class CreateChampionContactLoggedEmailAttachments < ActiveRecord::Migration
  def change
    create_table :champion_contact_logged_email_attachments do |t|
      t.references :champion_contact_logged_email, index: {:name => 'index_cc_le' }
      t.attachment :file

      t.timestamps
    end
  end
end
