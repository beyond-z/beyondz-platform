class StaffNotifications < ActionMailer::Base
  default from: '"Website Signup Notifier" <no-reply@beyondz.org>'

  def new_user(new_user)
    @user = new_user

    if Rails.env.production?
      to = 'signup-notification@beyondz.org'
    else
      to = 'tech@beyondz.org'
    end

    mail(to: to, subject: 'New user sign up')
  end
end
