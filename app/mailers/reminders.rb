# heroku addons:add scheduler 

class Reminders < ActionMailer::Base
  default from: "no-reply@beyondz.org"

  def assignment_nearly_due(to, name, assignment_name, link)
    @name = name
    @link = link
    @assignment_name = assignment_name

    mail to: to
  end
end
