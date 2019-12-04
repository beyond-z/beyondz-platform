class CalendlyInvitee < ActiveRecord::Base
  belongs_to :user

  def update_supplemental_info_on_salesforce

  end

  def self.by_event_type_and_invitee_uuids(event_type_uuid, invitee_uuid)
    return (self.find_by(event_type_uuid: event_type_uuid, invitee_uuid: invitee_uuid) ||
            self.new(event_type_uuid: event_type_uuid, invitee_uuid: invitee_uuid))
  end
end
