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
    mail(to: user.email, subject: "Please tell us about your Braven Network experience")
  end

  def champion_survey_reminder(champion, cc)
    @champion = champion
    @cc = cc
    mail(to: champion.email, subject: "Please tell us about your Braven Network experience")
  end
end
