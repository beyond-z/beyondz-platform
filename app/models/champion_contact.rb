class ChampionContact < ActiveRecord::Base
  def self.active(user_id)
    # A request is still active until BOTH surveys are answered documenting a response
    # or until the fellow one is answered and it becomes more than 10 days old without
    # a response from the champion.
    ChampionContact.where(:user_id => user_id).where("
      (fellow_survey_answered_at IS NULL OR reminder_requested = true)
      OR
      (champion_survey_answered_at IS NULL AND created_at > ?)
    ", 9.days.ago.end_of_day)
  end

  def security_hash
    Digest::SHA1.hexdigest("#{id}-#{nonce}-#{champion_id}-#{user_id}")[0 .. 6]
  end

  def champion_email
    "c#{id}-#{security_hash}@champions.bebraven.org"
  end

  def fellow_email
    "f#{id}-#{security_hash}@champions.bebraven.org"
  end

  def champion_email_with_name
    champion = Champion.find(champion_id)
    "#{champion.name} via Braven Champions <#{champion_email}>"
  end

  def fellow_email_with_name
    fellow = User.find(user_id)
    "#{fellow.name} via Braven Champions <#{fellow_email}>"
  end

  def self.send_reminders
    # if a week has passed and the fellow hasn't answered the survey yet, we email them asking them to fill it out
    # similarly, if a week has passed after the contact request and the champion hasn't answered, we ask them too
    ChampionContact.where("
      ((fellow_survey_answered_at IS NULL OR champion_survey_answered_at IS NULL)
      AND (fellow_survey_email_sent != TRUE OR champion_survey_email_sent != TRUE))
      AND first_email_from_fellow_sent < ?",
      1.week.ago.end_of_day).each do |cc|
      if cc.fellow_survey_answered_at.nil? && !cc.fellow_survey_email_sent
        # remind fellow
        Reminders.fellow_survey_reminder(User.find(cc.user_id), cc).deliver
        cc.fellow_survey_email_sent = true
        cc.save
      end

      if cc.champion_survey_answered_at.nil? && !cc.champion_survey_email_sent
        # remind champion
        Reminders.champion_survey_reminder(Champion.find(cc.champion_id), cc).deliver
        cc.champion_survey_email_sent = true
        cc.save
      end
    end
  end
end
