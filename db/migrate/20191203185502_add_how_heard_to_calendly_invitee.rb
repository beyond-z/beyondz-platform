class AddHowHeardToCalendlyInvitee < ActiveRecord::Migration
  def change
  	add_column :calendly_invitees, :how_heard, :string
  end
end