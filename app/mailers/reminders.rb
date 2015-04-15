# heroku addons:add scheduler

require 'digest/sha2'
class Reminders < ActionMailer::Base
  default from: 'no-reply@beyondz.org'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@beyondz.org>" }

  def assignment_nearly_due(to, name, assignment_name, link)
    @name = name
    @link = link
    @assignment_name = assignment_name

    mail to: to
  end
end
