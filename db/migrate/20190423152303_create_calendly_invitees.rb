class CreateCalendlyInvitees < ActiveRecord::Migration
  def change
    create_table :calendly_invitees do |t|
      t.string :assigned_to
      t.string :event_type_uuid
      t.string :event_type_name
      t.datetime :event_start_time
      t.datetime :event_end_time
      t.string :invitee_uuid, index: true
      t.string :invitee_first_name
      t.string :invitee_last_name
      t.string :invitee_email
      t.string :answer_1
      t.string :answer_2
      t.string :answer_3
      t.string :answer_4
      t.string :answer_5
      t.string :answer_6
      t.string :answer_7
      t.string :answer_8
      t.string :answer_9
      t.string :answer_10
      t.string :answer_11
      t.string :answer_12
      t.string :answer_13
      t.string :answer_14
      t.string :answer_15
      t.references :user, index: true
      t.string :salesforce_contact_id, index: true
      t.string :salesforce_campaign_member_id
      t.string :college_major
      t.string :industry

      t.timestamps
    end
  end
end
