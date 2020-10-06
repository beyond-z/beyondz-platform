class ChampionContactLoggedEmailAttachment < ActiveRecord::Base
  belongs_to :champion_contact_logged_email
  has_attached_file :file
  do_not_validate_attachment_file_type :file
end
