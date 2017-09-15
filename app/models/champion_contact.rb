class ChampionContact < ActiveRecord::Base
  def self.active(user_id)
    ChampionContact.where(:user_id => user_id).where("fellow_survey_answered_at IS NULL OR reminder_requested = true")
  end
end
