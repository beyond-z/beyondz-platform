require 'csv'
require 'zlib'

# This uses the following secrets:
#
# Secret                                                   | Explanation
# ==========================================================================================================
# Rails.application.secrets.canvas_access_token            | Access token from user settings
# Rails.application.secrets.canvas_server                  | The domain for canvas, e.g. portal.bebraven.org
# Rails.application.secrets.canvas_port                    | Probably 443 for https
# Rails.application.secrets.canvas_use_ssl                 | Should be true in most cases - uses https
# Rails.application.secrets.canvas_allow_self_signed_ssl   | Set to true when talking to a dev server
#

module BeyondZ
  # This communicates with the Canvas LMS through its REST API
  # allowing interoperation between it and our own system.
  class LMS

    public

    # Will get a list of assignments for the course. To find an assignment by name,
    # run this, then do a linear search through it for one with name == whatever
    # and get the id out.
    #
    # I recommend causing this.
    #
    # See also: https://canvas.instructure.com/doc/api/assignments.html
    #
    # this function will include the overrides.
    def get_assignments(course_id)

      request = Net::HTTP::Get.new(
        "/api/v1/courses/#{course_id}/assignments?include=overrides&access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end

    def trigger_qualtrics_preparation(course_id, preaccel_id, postaccel_id, additional_data)
      request = Net::HTTP::Post.new("/bz/prepare_qualtrics_links")
      data = {
        'access_token' => Rails.application.secrets.canvas_access_token,
        'course_id' => course_id,
        'preaccel_id' => preaccel_id,
        'postaccel_id' => postaccel_id,
        'additional_data' => additional_data.to_json
      }
      request.set_form_data(data)
      response = open_canvas_http.request(request)
      response.body
    end

    # Gets an assignment submission for a student
    #
    # Note that for an upload, the file will be under returned["attachments"][0]["url"]
    #
    # See: https://canvas.instructure.com/doc/api/submissions.html#method.submissions_api.show
    def get_submission(course_id, assignment_id, student_id)
      request = Net::HTTP::Get.new(
        "/api/v1/courses/#{course_id}/assignments/#{assignment_id}/submissions/#{student_id}?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)

      info
    end

    def get_events(course_id)
      request = Net::HTTP::Get.new(
        "/api/v1/calendar_events?per_page=300&all_events=true&context_codes[]=course_#{course_id}&access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end


    def destroy_user(user_id)
      request = Net::HTTP::Delete.new(
        "/api/v1/bz/delete_user/#{user_id}?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)
      response
    end

    def set_due_dates(assignment_object)
      request = Net::HTTP::Put.new(
        "/api/v1/courses/#{assignment_object['course_id']}/assignments/#{assignment_object['id']}",
        initheader = {'Content-Type' => 'application/json'}
      )
      arg = {}
      arg['access_token'] = Rails.application.secrets.canvas_access_token
      arg['assignment'] = assignment_object
      arg['assignment']['assignment_overrides'] = assignment_object['overrides'] # WTF api
      request.body = arg.to_json

      response = open_canvas_http.request(request)

      response
    end

    def set_event(event_object)
      request = Net::HTTP::Put.new(
        "/api/v1/calendar_events/#{event_object['event_id']}",
        initheader = {'Content-Type' => 'application/json'}
      )
      arg = {}
      arg['access_token'] = Rails.application.secrets.canvas_access_token
      arg['calendar_event'] = event_object.except('event_id')
      request.body = arg.to_json

      response = open_canvas_http.request(request)

      response.body
    end

    # assumes parent_event_id is set
    def create_event(event_object)

      response = nil

      if event_object['parent_event_id']
        # new section in existing event


        # we need to get the existing data to populate child events
        # lest it delete existing ones when we try to add one!
        request = Net::HTTP::Get.new(
          "/api/v1/calendar_events/#{event_object['parent_event_id']}?access_token=#{Rails.application.secrets.canvas_access_token}"
        )
        response = open_canvas_http.request(request)
        info = JSON.parse response.body



        request = Net::HTTP::Put.new(
          "/api/v1/calendar_events/#{event_object['parent_event_id']}",
          initheader = {'Content-Type' => 'application/json'}
        )
        arg = {}
        arg['access_token'] = Rails.application.secrets.canvas_access_token

        # populate from old child events
        cedx = 0
        child_event_data = {}
        info["child_events"].each do |ce|
          ced = {}
          ced['start_at'] = ce['start_at']
          ced['end_at'] = ce['end_at']
          ced['context_code'] = ce['context_code']
          child_event_data[cedx.to_s] = ced
          cedx += 1
        end

        ced = {}
        ced['start_at'] = event_object['start_at']
        ced['end_at'] = event_object['end_at']
        ced['context_code'] = event_object['context_code']
        child_event_data[cedx.to_s] = ced
        new_event_object = {}
        new_event_object['child_event_data'] = child_event_data
        arg['calendar_event'] = new_event_object
        request.body = arg.to_json
        response = open_canvas_http.request(request)
      else
        # new event

        request = Net::HTTP::Post.new(
          "/api/v1/calendar_events",
          initheader = {'Content-Type' => 'application/json'}
        )
        arg = {}
        arg['access_token'] = Rails.application.secrets.canvas_access_token
        arg['calendar_event'] = event_object.except('event_id')
        request.body = arg.to_json
        response = open_canvas_http.request(request)
      end

      response.body
    end


    def commit_new_due_dates(email, changed)
      changed.each do |key, value|
        self.set_due_dates(value)
      end
      StaffNotifications.canvas_due_dates_updated(email).deliver
    end

    def delete_event(id)
      request = Net::HTTP::Delete.new("/api/v1/calendar_events/#{id}")
      data = {
        'access_token' => Rails.application.secrets.canvas_access_token,
        'cancel_reason' => 'clear via join server'
      }
      request.set_form_data(data)
      open_canvas_http.request(request)
    end

    def commit_new_events(email, changed, delete_existing, course_id)

      if delete_existing
        get_events(course_id).each do |event|
          delete_event(event["id"])
        end
      end

      replies = []
      new_events = {}
      changed.each do |key, value|
        if value['event_id'].blank?
          if value['parent_event_id'].blank?
            if new_events[value['title']].nil?
              new_events[value['title']] = value.clone
              new_events[value['title']]['context_code'] = "course_#{value['course_id']}"
              new_events[value['title']]['child_event_data'] = {}
            end
            ced = {}
            ced['start_at'] = value['start_at']
            ced['end_at'] = value['end_at']
            ced['context_code'] = value['context_code']
            new_events[value['title']]['child_event_data'][value['context_code']] = ced
          else
            replies << self.create_event(value.except('event_id'))
          end
        else
          replies << self.set_event(value)
        end
      end

      # I need to find all the ones with the same title and combine them
      # into child_event_data under a newly created parent event
      new_events.each do |key, value|
        replies << self.create_event(value.except('event_id'))
      end

      StaffNotifications.canvas_events_updated(email, replies.inspect).deliver
    end


    def get_courses
      request = Net::HTTP::Get.new(
        "/api/v1/courses?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end

    def update_nlu_login(user_id, login_id)
      # I need to find the existing login id with an nlu id for the user,
      # then update it. If it doesn't exist, I need to create one.
      request = Net::HTTP::Get.new("/api/v1/users/#{user_id}/logins?access_token=#{Rails.application.secrets.canvas_access_token}")
      response = open_canvas_http.request(request)
      info = get_all_from_pagination(response)

      lid = nil

      info.each do |login|
        if login["unique_id"].ends_with? '@nlu.edu'
          lid = login["id"]
          break
        end
      end

      if lid.nil?
        # create new one
        request = Net::HTTP::Post.new("/api/v1/accounts/1/logins")
        data = {
          'access_token' => Rails.application.secrets.canvas_access_token,
          'login[unique_id]' => login_id,
          'user[id]' => user_id
        }
        request.set_form_data(data)
        open_canvas_http.request(request)
      else
        # update existing one
        request = Net::HTTP::Put.new("/api/v1/accounts/1/logins/#{lid}")
        data = {
          'access_token' => Rails.application.secrets.canvas_access_token,
          'login[unique_id]' => login_id
        }
        request.set_form_data(data)
        open_canvas_http.request(request)
      end

    end

    # Creates a user in canvas based on the passed user
    # storing the new canvas user id in the object.
    #
    # Be sure to call user.save at some point after using this.
    def create_user_in_canvas(user, username, timezone = nil, docusign_template_id = nil)
      user_student_id = nil
      enrollment = Enrollment.find_by_user_id(user.id)
      user_student_id = enrollment.student_id unless enrollment.nil?

      # the v1 is API version, only one option available in Canvas right now
      # accounts/1 refers to the Beyond Z account, which is the only one
      # we use since it is a custom installation.
      request = Net::HTTP::Post.new('/api/v1/accounts/1/users')
      request.set_form_data(
        'access_token' => Rails.application.secrets.canvas_access_token,
        'user[name]' => user.name,
        'user[short_name]' => user.first_name,
        'user[sortable_name]' => "#{user.last_name}, #{user.first_name}",
        'user[skip_registration]' => true,
        'user[time_zone]' => timezone,
        'user[docusign_template_id]' => docusign_template_id,
        'pseudonym[unique_id]' => username,
        'pseudonym[send_confirmation]' => false,
        'communication_channel[type]' => 'email',
        'communication_channel[address]' => user.email,
        'communication_channel[skip_confirmation]' => true,
        'communication_channel[confirmation_url]' => true,
        'pseudonym[sis_user_id]' => "BVID#{user.id}-SISID#{user_student_id}"
      )
      response = open_canvas_http.request(request)

      new_canvas_user = JSON.parse response.body

      # this will be set if we actually created a new user
      # reasons why it might fail would include existing user
      # already having the email address

      # Not necessarily an error but for now i'll just make it throw
      raise "Couldn't create user #{username} <#{user.email}> in canvas #{response.body}" if new_canvas_user['id'].nil?

      user.canvas_user_id = new_canvas_user['id']

      # Not necessary (and didn't seem to actually work?) since we changed the code
      # on the Canvas side to mark them registered if skip_confirmation is specified.
      #if new_canvas_user['confirmation_url']
      #    request = Net::HTTP::Get.new(new_canvas_user['confirmation_url'])
      #    open_canvas_http.request(request)
      #end

      user
    end

    # Updates a user in canvas. Only updates the parameters that are explicity set. 
    # Set a parameter to empty string to clear it. Nil means don't touch it.
    def update_user_in_canvas(user, timezone: nil, docusign_template_id: nil)
      raise "Couldn't update user <#{user.email}> in canvas because user.canvas_user_id is nil" if user.canvas_user_id.nil?
      data = { 'access_token' => Rails.application.secrets.canvas_access_token }
      data['user[time_zone]'] = timezone unless timezone.nil?
      data['user[docusign_template_id]'] = docusign_template_id unless docusign_template_id.nil?

      return if data.length <= 1

      request = Net::HTTP::Put.new("/api/v1/users/#{user.canvas_user_id}")
      request.set_form_data(data)
      response = open_canvas_http.request(request)

      raise "Couldn't update user <#{user.email}> in canvas #{response.body}" if response.code != '200'

      JSON.parse response.body
    end

    # Looks up the user in Canvas and creates the user in Canvas if they don't exist.
    # Otherwise, sets the canvas ID locally if the user exists and updates the
    # DocuSign template ID if necessary
    #
    # Don't forget to call user.save after using this.
    def sync_user_logins(user, username, timezone = nil, docusign_template_id = nil)
      # if they are already on canvas, no need to look up again
      if user.canvas_user_id.nil?
        # but if not, we will try to sync by username
        # and create if necessary
        canvas_user = find_user_in_canvas(username)
        if canvas_user.nil?
          create_user_in_canvas(user, username, timezone, docusign_template_id)
        else
          user.canvas_user_id = canvas_user['id']
        end
      else
        # The DocuSign template could have changed after we first created the user with it. So update it for existing users.
        update_user_in_canvas(user, :docusign_template_id => docusign_template_id)
      end

      user
    end

    def find_user_in_canvas(email)
      request = Net::HTTP::Get.new(
        '/api/v1/accounts/1/users?' \
        "access_token=#{Rails.application.secrets.canvas_access_token}&" \
        "search_term=#{URI.encode_www_form_component(email)}"
      )
      response = open_canvas_http.request(request)

      users = JSON.parse response.body

      users.length == 1 ? users[0] : nil
    end

    # When we change an email, it needs to change the login and the
    # communication channel. This method does that.
    def change_user_email(uid, old_email, new_email)

      # Update login - need to look it up then edit it by id
      request = Net::HTTP::Get.new(
        "/api/v1/users/#{uid}/logins?" \
        "access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)

      logins = JSON.parse response.body

      login_id = nil

      logins.each do |login|
        if login['unique_id'] == old_email
          login_id = login['id']
          break
        end
      end

      # Update primary communication channel (which is the email too)
      # Canvas doesn't have an edit function, so we'll make a new one, then
      # search for and delete any with the old one
      request = Net::HTTP::Post.new(
        "/api/v1/users/#{uid}/communication_channels"
      )
      data = {
        'communication_channel[address]' => new_email,
        'communication_channel[type]' => 'email',
        'access_token' => Rails.application.secrets.canvas_access_token,
        'communication_channel[skip_confirmation]' => true
      }
      request.set_form_data(data)
      response = open_canvas_http.request(request)

      # We might not have found the old email in the event
      # of it already being changed on Canvas; this isn't an
      # error condition, we should still try to update the CC
      # even if the login doesn't already match.
      if login_id
        request = Net::HTTP::Put.new(
          "/api/v1/accounts/1/logins/#{login_id}"
        )
        data = {
          'login[unique_id]' => new_email,
          'access_token' => Rails.application.secrets.canvas_access_token
        }
        request.set_form_data(data)
        response = open_canvas_http.request(request)
      end

      request = Net::HTTP::Delete.new(
        "/api/v1/users/#{uid}/communication_channels/email/#{old_email}?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)

    end

    # Enrolls the user in the new course, without modifying any
    # existing data
    def enroll_user_in_course(user, course_id, role, section)
      return if role.nil?

      role = role.capitalize

      request = Net::HTTP::Post.new("/api/v1/courses/#{course_id}/enrollments")
      data = {
        'access_token' => Rails.application.secrets.canvas_access_token,
        'enrollment[user_id]' => user.canvas_user_id,
        'enrollment[type]' => "#{role}Enrollment",
        'enrollment[enrollment_state]' => 'active',
        'enrollment[limit_privileges_to_course_section]' => true,
        'enrollment[notify]' => false
      }
      unless section.nil?
        data['enrollment[course_section_id]'] = get_section_by_name(course_id, section, true)['id']
      end
      request.set_form_data(data)
      open_canvas_http.request(request)
    end

    # Syncs the user enrollments with the given data, by unenrolling
    # from existing courses, if necessary, and enrolling them in the
    # new course+section.
    #
    # The goal of this method is to make Canvas's internal data match
    # the spreadsheet data, allowing for bulk fixes via csv import.
    def sync_user_course_enrollment(user, course_id, role, section)
      @course_enrollment_cache = {} if @course_enrollment_cache.nil?

      if @course_enrollment_cache[course_id].nil?
        @course_enrollment_cache[course_id] = get_course_enrollments(course_id)
      end

      existing_enrollment = nil
      @course_enrollment_cache[course_id].each do |enrollment|
        if enrollment['user_id'] == user.canvas_user_id
          existing_enrollment = enrollment
          break
        end
      end

      if role.nil?
        cancel_enrollment(existing_enrollment)
        return
      end

      role = role.capitalize
      section_id = get_section_by_name(course_id, section, true)['id']
      type = "#{role}Enrollment"

      if !existing_enrollment.nil? && existing_enrollment['course_section_id'] != section_id
        # The user is being moved to a new section/cohort - cancel the old one and re-enroll
        cancel_enrollment(existing_enrollment)
        existing_enrollment = nil
      end

      if !existing_enrollment.nil? && existing_enrollment['type'] != type
        # User role changed, need to cancel and reenroll
        cancel_enrollment(existing_enrollment)
        existing_enrollment = nil
      end

      if existing_enrollment.nil?
        # They aren't enrolled properly, enroll them now
        enroll_user_in_course(user, course_id, role, section)
      end

      # Otherwise, the existing_enrollment passed all tests, we don't need to do anything
    end

    # Returns an array of enrollments objects for the user.
    # https://canvas.instructure.com/doc/api/enrollments.html
    def get_user_enrollments(user_id)
      request = Net::HTTP::Get.new(
        "/api/v1/users/#{user_id}/enrollments?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end

    # Returns an array of enrollments objects for the course.
    # https://canvas.instructure.com/doc/api/enrollments.html
    def get_course_enrollments(course_id)
      request = Net::HTTP::Get.new(
        "/api/v1/courses/#{course_id}/enrollments?per_page=100&access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)
      info = nil
      if response.code == '200'
        info = get_all_from_pagination(response)
      else
        raise "Course #{course_id} does not exist. #{response.body}"
      end

      info
    end


    # Get the enrollment object from the get_user_enrollments method
    def cancel_enrollment(enrollment)
      return if enrollment.nil?

      request = Net::HTTP::Delete.new("/api/v1/courses/#{enrollment['course_id']}/enrollments/#{enrollment['id']}")
      data = {
        'access_token' => Rails.application.secrets.canvas_access_token,
        'task' => 'delete'
      }
      request.set_form_data(data)
      open_canvas_http.request(request)
    end

    def get_section_by_name(course_id, section_name, create_if_not_there = true)
      section_info = read_sections(course_id)
      if section_info[section_name].nil? && create_if_not_there
        request = Net::HTTP::Post.new("/api/v1/courses/#{course_id}/sections")
        request.set_form_data(
          'access_token' => Rails.application.secrets.canvas_access_token,
          'course_section[name]' => section_name
        )
        response = open_canvas_http.request(request)

        new_section = JSON.parse response.body

        section_info[section_name] = new_section

      end

      section_info[section_name]
    end

    def get_section_by_id(course_id, section_id)
      read_sections(course_id)
      return @section_info_by_id[course_id][section_id.to_i]
    end

    def get_page_data(course_id, user_id = nil)
      request = Net::HTTP::Get.new(
        "/api/v1/courses/#{course_id}/analytics/#{user_id.nil? ? '' : "users/#{user_id}/"}activity?per_page=100&access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = open_canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end

    def get_user_data_spreadsheet(course_id)
      enrollments = get_course_enrollments(course_id)

      read_sections(course_id)

      # We want the ID map instead of the name map since we're
      # pulling info that way from Canvas instead of populating
      # Canvas like we are in the rest of the file.
      section_info_by_id = @section_info_by_id[course_id]

      totals = {}

      a = 0

      got = {}

      enrollments.map! do |enrollment|
        # We want to pull users only once, even if they are enrolled in the
        # course multiple times (such as in different sections)
        if got[enrollment['user_id']]
          next
        end

        got[enrollment['user_id']] = true

        data = get_page_data(course_id, enrollment['user_id'])
        data = data['page_views']
        enrollment['page_data'] = data

        cohort = ''
        if enrollment['course_section_id'] && section_info_by_id[enrollment['course_section_id']]
          cohort = section_info_by_id[enrollment['course_section_id']]['name']
        end

        enrollment['cohort'] = cohort

        if enrollment['page_data']
          enrollment['page_data'].each do |k, v|
            totals[k] = 0 if totals[k].nil?
            totals[k] += v
          end
        end

        enrollment
      end

      CSV.generate do |csv|
        header = []
        header << 'User Canvas ID'
        header << 'User Name'
        header << 'User Email'
        header << 'Cohort'
        totals.keys.sort.each do |k|
          header << k
        end

        csv << header

        enrollments.each do |enrollment|
          if enrollment.nil? || enrollment['user'].nil?
            next
          end
          row = []
          row << enrollment['user']['id']
          row << enrollment['user']['name']
          row << enrollment['user']['login_id']
          row << enrollment['cohort']

          totals.keys.sort.each do |k|
            if enrollment['page_data'] && enrollment['page_data'][k]
              row << (enrollment['page_data'][k])
            else
              row << 0
            end
          end

          csv << row
        end

        row = []
        row << ''
        row << 'Total'
        row << ''

        totals.keys.sort.each do |k|
          row << totals[k]
        end

        csv << row

      end
    end

    def email_user_data_spreadsheet(email, course_id)
      StaffNotifications.canvas_views_ready(email, get_user_data_spreadsheet(course_id)).deliver
    end

    def get_assignment_due_dates_spreadsheet(course_id)
      assignments = get_assignments(course_id)
      CSV.generate do |csv|
        header = []
        header << 'Assignment ID (do not change)'
        header << 'Course ID (do not change)'
        header << 'Name'
        header << 'Section Name'
        header << 'Due Date'
        header << 'Until'
        header << 'Override ID (do not change, but leave blank for new section)'
  
        csv << header
  
        assignments.each do |a|
          exportable = []
          exportable << a['id']
          exportable << a['course_id']
          exportable << a['name']
          exportable << ''
          exportable << export_date_translation(a['due_at'])
          exportable << export_date_translation(a['lock_at'])
          exportable << ''
  
          csv << exportable
  
          if a['overrides']
            a['overrides'].each do |override|
              exportable = []
              exportable << a['id']
              exportable << a['course_id']
              exportable << a['name']
              exportable << override['title']
              exportable << export_date_translation(override['due_at'])
              exportable << export_date_translation(override['lock_at'])
              exportable << override['id']
  
              csv << exportable
            end
          end
        end
      end
    end

    def email_assignment_due_dates_spreadsheet(email, course_id)
      StaffNotifications.canvas_due_dates_ready(email, get_assignment_due_dates_spreadsheet(course_id)).deliver
    end


    def get_events_for_email(email, course_id)
        lms = BeyondZ::LMS.new

        events = lms.get_events(course_id)

        StaffNotifications.canvas_events_ready(email, csv_events_export(course_id, events)).deliver
    end

    def csv_events_export(course_id, events)
      lms = BeyondZ::LMS.new
      CSV.generate do |csv|
        header = []
        header << 'Event ID (do not change)'
        header << 'Course ID (do not change)'
        header << 'Parent (do not change)'
        header << 'Section Name'
        header << 'Title'
        header << 'Start At'
        header << 'End At'
        header << 'Description (HTML)'
        header << 'Location Name'
        header << 'Location Address'
        header << 'metadata:' + course_id + ':' # + Base64.encode64(Zlib::Deflate.deflate(events.to_json))

        csv << header

        events.each do |a|
          exportable = []

          section = ''
          if a['context_code'].starts_with? 'course_section_'
            section = lms.get_section_by_id(course_id, a['context_code']['course_section_'.length .. -1])
            if section.nil?
              section = ''
            else
              section = section['name']
            end
          end

          exportable << a['id']
          exportable << a['context_code']
          exportable << a['parent_event_id']
          exportable << section
          exportable << a['title']
          exportable << export_date_translation(a['start_at'])
          exportable << export_date_translation(a['end_at'])
          exportable << a['description']
          exportable << a['location_name']
          exportable << a['location_address']

          csv << exportable
        end
      end
    end

    # This is the translation when we're exporting from Canvas.
    #
    # So it gives us the ISO format, and needs to return a user-
    # friendly format in a user-friendly timezone.
    def export_date_translation(date_string)
      if date_string.nil? || date_string.empty?
        return date_string
      end
      dt = DateTime.iso8601(date_string)
      # Best guess for friendly timezone... using the city means
      # the library will handle stuff like DST... for now though.
      # The Canvas course API doesn't export the TZ setting, and even if
      # it did, Rails likes the city name rather than the offset so... i think
      # this will be best we can for now.
      #
      # Pacific time is the latest TZ in the US, so if it is set to end of day there
      # at least the date will always be right in Eastern time too.
      #
      # It will print the tz in the string for the user to read and even modify.
      dt = dt.in_time_zone('America/Los_Angeles')

      # It strips off the Standard or Daylight abbreviation from it because we
      # don't want to user to have to think about that. We'll magic it up on the
      # import side based on the date and assuming wall time is specified by the user.
      dt.strftime('%Y-%m-%d %H:%M %Z').sub('S', '').sub('D', '')
    end



    private

    def read_sections(course_id)
      if @section_info.nil?
        @section_info = {}
        @section_info_by_id = {}
      end

      if @section_info[course_id].nil?
        @section_info[course_id] = {}
        @section_info_by_id[course_id] = {}

        request = Net::HTTP::Get.new(
          "/api/v1/courses/#{course_id}/sections?access_token=#{Rails.application.secrets.canvas_access_token}"
        )
        response = open_canvas_http.request(request)
        info = get_all_from_pagination(response)

        info.each do |section|
          @section_info[course_id][section['name']] = section
          @section_info_by_id[course_id][section['id']] = section
        end
      end

      @section_info[course_id]
    end

    def get_all_from_pagination(response)
      info = JSON.parse response.body
      while response
        link = response.header['link']
        break if link.nil?

        next_url = nil
        link.split(',').each do |part|
          if part.ends_with?('; rel="next"')
            next_url = part[1 .. link.index('>')-1]
            break
          end
        end

        if next_url
          next_url = next_url[8 .. -1] # trim off the http
          next_url = next_url[next_url.index('/') .. -1] # we want the path and the query string off it
          if next_url.index('?')
            next_url += '&'
          else
            next_url += '?'
          end
          next_url += "access_token=#{Rails.application.secrets.canvas_access_token}"

          request = Net::HTTP::Get.new(next_url)
          response = open_canvas_http.request(request)
          more_info = JSON.parse response.body
          info.concat(more_info)
        else
          response = nil
        end
      end

      info
    end

    # Opens a connection to the canvas http api (the address of the
    # server is pulled from environment variables).
    #
    # This is a separate method that opens a member @canvas_http so
    # we can reuse the connection across several requests for performance.
    #
    def open_canvas_http
 
    # NOTE: disabling the re-use of connections. When connecting to Heroku hosted
    # apps over SSL, the first request works but the second fails with:
    # "OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=error: tlsv1 alert protocol version"
    # Leaving this method here in case we figure out how to re-use SSL connections against those servers,
    # we can likely just fix it here.
    # if @canvas_http.nil?
        @canvas_http = Net::HTTP.new(Rails.application.secrets.canvas_server, Rails.application.secrets.canvas_port)
        if Rails.application.secrets.canvas_use_ssl
          @canvas_http.use_ssl = true
          if Rails.application.secrets.canvas_allow_self_signed_ssl
            @canvas_http.verify_mode = OpenSSL::SSL::VERIFY_NONE # self-signed cert would fail
          end
        end
    # end

      @canvas_http
    end
  end
end
