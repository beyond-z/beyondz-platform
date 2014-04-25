class Notifications < ActionMailer::Base
  default from: 'no-reply@beyondz.org'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notifications.forgot_password.subject
  #
  def forgot_password(to, name, link)
    @name = name
    @link = link

    mail to: to
  end
end
