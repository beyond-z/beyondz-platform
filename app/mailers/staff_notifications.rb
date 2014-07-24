class StaffNotifications < ActionMailer::Base
  default from: '"Website Signup Notifier" <no-reply@beyondz.org>'

  def new_enrollment(new_user)
    @user = new_user

    if Rails.env.staging?
      to = 'tech@beyondz.org'
    else
      to = 'signup-notification@beyondz.org'
    end

    mail(to: to, subject: 'New user sign up')
  end
end
