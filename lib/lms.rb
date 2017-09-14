require 'csv'

module BeyondZ
  # This communicates with the Canvas LMS through its REST API
  # allowing interoperation between it and our own system.
  class LMS

    public

    def get_assignments(course_id)
      open_canvas_http

      request = Net::HTTP::Get.new(
        "/api/v1/courses/#{course_id}/assignments?include=overrides&access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end

    def get_events(course_id)
      open_canvas_http

      request = Net::HTTP::Get.new(
        "/api/v1/calendar_events?all_events=true&context_codes[]=course_#{course_id}&access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end


    def destroy_user(user_id)
      open_canvas_http

      request = Net::HTTP::Delete.new(
        "/api/v1/bz/delete_user/#{user_id}?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)
      response
    end

    def set_due_dates(assignment_object)
      open_canvas_http

      request = Net::HTTP::Put.new(
        "/api/v1/courses/#{assignment_object['course_id']}/assignments/#{assignment_object['id']}",
        initheader = {'Content-Type' => 'application/json'}
      )
      arg = {}
      arg['access_token'] = Rails.application.secrets.canvas_access_token
      arg['assignment'] = assignment_object
      arg['assignment']['assignment_overrides'] = assignment_object['overrides'] # WTF api
      request.body = arg.to_json

      response = @canvas_http.request(request)

      response
    end

    def set_event(event_object)
      open_canvas_http

      request = Net::HTTP::Put.new(
        "/api/v1/calendar_events/#{event_object['event_id']}",
        initheader = {'Content-Type' => 'application/json'}
      )
      arg = {}
      arg['access_token'] = Rails.application.secrets.canvas_access_token
      arg['calendar_event'] = event_object.except('event_id')
      request.body = arg.to_json

      response = @canvas_http.request(request)

      response
    end

    def create_event(event_object)
      open_canvas_http

      request = Net::HTTP::Post.new(
        "/api/v1/calendar_events",
        initheader = {'Content-Type' => 'application/json'}
      )
      arg = {}
      arg['access_token'] = Rails.application.secrets.canvas_access_token
      arg['calendar_event'] = event_object
      request.body = arg.to_json

      response = @canvas_http.request(request)

      response
    end


    def commit_new_due_dates(email, changed)
      changed.each do |key, value|
        self.set_due_dates(value)
      end
      StaffNotifications.canvas_due_dates_updated(email).deliver
    end

    def commit_new_events(email, changed)
      changed.each do |key, value|
        if value['event_id'].nil?
           self.create_event(value.except('event_id'))
        else
          self.set_event(value)
        end
      end
      StaffNotifications.canvas_events_updated(email).deliver
    end


    def get_courses
      open_canvas_http

      request = Net::HTTP::Get.new(
        "/api/v1/courses?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end

    # Creates a user in canvas based on the passed user
    # storing the new canvas user id in the object.
    #
    # Be sure to call user.save at some point after using this.
    def create_user(user, username)
      open_canvas_http

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
        'user[terms_of_use]' => true,
        'user[skip_registration]' => true,
        'pseudonym[unique_id]' => username,
        'pseudonym[send_confirmation]' => false,
        'communication_channel[type]' => 'email',
        'communication_channel[address]' => user.email,
        'communication_channel[skip_confirmation]' => true,
        'communication_channel[confirmation_url]' => true,
        'pseudonym[sis_user_id]' => "BVID#{user.id}-SISID#{user_student_id}"
      )
      response = @canvas_http.request(request)

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
      #    @canvas_http.request(request)
      #end

      user
    end

    # Looks up the user in canvas, setting the ID locally if found,
    # and creating the user on Canvas if not.
    #
    # Don't forget to call user.save after using this.
    def sync_user_logins(user, username)
      canvas_user = find_user(username)
      if canvas_user.nil?
        create_user(user, username)
      else
        user.canvas_user_id = canvas_user['id']
      end

      user
    end

    def find_user(email)
      open_canvas_http

      request = Net::HTTP::Get.new(
        '/api/v1/accounts/1/users?' \
        "access_token=#{Rails.application.secrets.canvas_access_token}&" \
        "search_term=#{URI.encode_www_form_component(email)}"
      )
      response = @canvas_http.request(request)

      users = JSON.parse response.body

      users.length == 1 ? users[0] : nil
    end

    # When we change an email, it needs to change the login and the
    # communication channel. This method does that.
    def change_user_email(uid, old_email, new_email)
      open_canvas_http

      # Update login - need to look it up then edit it by id

      request = Net::HTTP::Get.new(
        "/api/v1/users/#{uid}/logins?" \
        "access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)

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
      response = @canvas_http.request(request)

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
        response = @canvas_http.request(request)
      end

      request = Net::HTTP::Delete.new(
        "/api/v1/users/#{uid}/communication_channels/email/#{old_email}?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)

    end

    # Enrolls the user in the new course, without modifying any
    # existing data
    def enroll_user_in_course(user, course_id, role, section)
      return if role.nil?

      open_canvas_http

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
      @canvas_http.request(request)
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
      open_canvas_http

      request = Net::HTTP::Get.new(
        "/api/v1/users/#{user_id}/enrollments?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)
      info = get_all_from_pagination(response)

      info
    end

    # Returns an array of enrollments objects for the course.
    # https://canvas.instructure.com/doc/api/enrollments.html
    def get_course_enrollments(course_id)
      open_canvas_http

      request = Net::HTTP::Get.new(
        "/api/v1/courses/#{course_id}/enrollments?per_page=100&access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)
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

      open_canvas_http

      request = Net::HTTP::Delete.new("/api/v1/courses/#{enrollment['course_id']}/enrollments/#{enrollment['id']}")
      data = {
        'access_token' => Rails.application.secrets.canvas_access_token,
        'task' => 'delete'
      }
      request.set_form_data(data)
      @canvas_http.request(request)
    end

    def get_section_by_name(course_id, section_name, create_if_not_there = true)
      section_info = read_sections(course_id)
      if section_info[section_name].nil? && create_if_not_there
        request = Net::HTTP::Post.new("/api/v1/courses/#{course_id}/sections")
        request.set_form_data(
          'access_token' => Rails.application.secrets.canvas_access_token,
          'course_section[name]' => section_name
        )
        response = @canvas_http.request(request)

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
      open_canvas_http

      request = Net::HTTP::Get.new(
        "/api/v1/courses/#{course_id}/analytics/#{user_id.nil? ? '' : "users/#{user_id}/"}activity?per_page=100&access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)
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

    private

    def read_sections(course_id)
      if @section_info.nil?
        @section_info = {}
        @section_info_by_id = {}
      end

      if @section_info[course_id].nil?
        @section_info[course_id] = {}
        @section_info_by_id[course_id] = {}

        open_canvas_http

        request = Net::HTTP::Get.new(
          "/api/v1/courses/#{course_id}/sections?access_token=#{Rails.application.secrets.canvas_access_token}"
        )
        response = @canvas_http.request(request)
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
          response = @canvas_http.request(request)
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
    def open_canvas_http
      if @canvas_http.nil?
        @canvas_http = Net::HTTP.new(Rails.application.secrets.canvas_server, Rails.application.secrets.canvas_port)
        if Rails.application.secrets.canvas_use_ssl
          @canvas_http.use_ssl = true
          if Rails.application.secrets.canvas_allow_self_signed_ssl
            @canvas_http.verify_mode = OpenSSL::SSL::VERIFY_NONE # self-signed cert would fail
          end
        end
      end

      @canvas_http
    end
  end
end
