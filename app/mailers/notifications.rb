class Notifications < ActionMailer::Base
  default from: "no-reply@beyondz.org"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notifications.forgot_password.subject
  #
  def forgot_password(to, name, newpw)
    @name = name
    @link = "http://platform.beyondz.org/users/login"
    @newpw = newpw

    mail to: to
  end
end
