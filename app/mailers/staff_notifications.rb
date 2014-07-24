class StaffNotifications < ActionMailer::Base
  default from: '"Website Signup Notifier" <no-reply@beyondz.org>'

  def new_enrollment(new_user)
    @user = new_user
    mail(to: 'signup-notification@beyondz.org', subject: 'New user sign up')
  end
end
