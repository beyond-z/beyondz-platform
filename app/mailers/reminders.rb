# heroku addons:add scheduler 

class Reminders < ActionMailer::Base
  default from: "no-reply@beyondz.org"

  def assignment_nearly_due(to, name, link)
    @name = name
    @link = link

    mail to: to
  end
end
