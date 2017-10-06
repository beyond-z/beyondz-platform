require 'digest/sha2'

class StaffNotifications < ActionMailer::Base
  default 'from' => '"Website Signup Notifier" <' + Rails.application.secrets.mailer_from_email + '>'

  # needed because gmail was filtering some messages: http://blog.mailgun.com/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default 'Message-ID' => ->(_v_) { "<#{SecureRandom.uuid}@bebraven.org>" }

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
    mail(to: 'tech@bebraven.org', subject: 'LMS User Mismatch')
  end

  def salesforce_sync_failed(msg)
    @msg = msg
    mail(to: 'tech@bebraven.org', subject: 'Salesforce Sync Failure')
  end

  def bug_report(user, bug_info)
    @user = user
    @bug_info = bug_info

    mail(to: 'tech@bebraven.org', subject: 'Bug in BZ platform')
  end

  def canvas_views_ready(email, data)
    attachments['get_canvas_page_views.csv'] = data
    mail(to: email, subject: 'Page views spreadsheet', from: 'Braven Website <' + Rails.application.secrets.mailer_from_email + '>')
  end

  def canvas_events_ready(email, data)
    attachments['events.csv'] = data
    mail(to: email, subject: 'Canvas Events spreadsheet', from: 'Braven Website <' + Rails.application.secrets.mailer_from_email + '>')
  end

  def canvas_due_dates_updated(email)
    mail(to: email, subject: 'Due date upload complete')
  end

  def canvas_events_updated(email, debug_info = "")
    @debug_info = debug_info
    mail(to: email, subject: 'Event upload complete')
  end

  def requested_spreadsheet_ready(email, filename, data)
    attachments[filename] = data
    mail(to: email, subject: 'Braven data sheet', from: 'Braven Website <' + Rails.application.secrets.mailer_from_email + '>')
  end


  def salesforce_report_ready(email, success, message)
    @success = success
    @message = message
    mail(to: email, subject: 'Salesforce report', from: 'Braven Website <' + Rails.application.secrets.mailer_from_email + '>')
  end
end
