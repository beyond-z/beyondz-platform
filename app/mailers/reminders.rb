# heroku addons:add scheduler

require 'digest/sha2'
class Reminders < ActionMailer::Base
  default 'from' => '"Braven" <' + Rails.application.secrets.mailer_from_email + '>'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@bebraven.org>" }

  def assignment_nearly_due(to, name, assignment_name, link)
    @name = name
    @link = link
    @assignment_name = assignment_name

    mail to: to
  end

  def fellow_survey_reminder(user, cc)
    @user = user
    @cc = cc
    mail(to: user.email, subject: "Please tell us about your Braven Champion experience")
  end

  def champion_survey_reminder(champion, cc)
    @champion = champion
    @cc = cc
    mail(to: champion.email, subject: "Please tell us about your Braven Champion experience")
  end

  def champion_unresponsive_notification(champion, cc)
    @champion = champion
    @cc = cc
    mail(to: champion.email, subject: "A Braven Fellow said they couldn't reach you")
  end

  def fellow_can_try_new_champion(user, champion, cc)
    @user = user
    @champion = champion
    @cc = cc

    mail(to: user.email, subject: "You can try a new Braven Champion")
  end

  def champion_flood_achieved(champion)
    @champion = champion
    mail(to: champion.email, subject: "You will not hear from any more Braven Fellows for a while")
  end
end
