class StaffNotifications < ActionMailer::Base
  default from: '"Website Signup Notifier" <no-reply@beyondz.org>'

  def new_user(new_user)
    @user = new_user
    mail(to: Rails.application.secrets.staff_email, subject: 'New user sign up')
  end

  def new_application(new_application)
    @enrollment = new_application
    mail(to: Rails.application.secrets.staff_email, subject: 'Application submitted')
  end

  # Notify the tech team about a user we think is in the LMS but isn't;
  # likely a bug.
  def lms_mismatch(user)
    @user = user
    @lms_server = Rails.application.secrets.canvas_server
    # we want this to go to the tech team always, not the staff in general
    # because it is most likely a code bug, but even if caused by manual
    # deletions, it will need some kind of database sync to fix
    mail(to: 'tech@beyondz.org', subject: 'LMS User Mismatch')
  end
end
