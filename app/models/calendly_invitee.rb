class CalendlyInvitee < ActiveRecord::Base
  belongs_to :user

  def update_supplemental_info_on_salesforce

  end

  def self.by_event_type_and_invitee_uuids(event_type_uuid, invitee_uuid)
    f = CalendlyInvitee.where(:event_type_uuid => event_type_uuid, :invitee_uuid => invitee_uuid)
    if f.any?
      return f.first
    else
      o = CalendlyInvitee.new
      o.event_type_uuid = event_type_uuid
      o.invitee_uuid = invitee_uuid
      return o
    end
  end
end
