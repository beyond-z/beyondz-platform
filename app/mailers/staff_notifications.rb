class StaffNotifications < ActionMailer::Base
  default from: '"Website Signup Notifier" <no-reply@beyondz.org>'

  def new_user(new_user)
    @user = new_user
    mail(to: Rails.application.secrets.staff_email, subject: 'New user sign up')
  end
end
