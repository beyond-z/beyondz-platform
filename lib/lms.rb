module BeyondZ
  # This communicates with the Canvas LMS through its REST API
  # allowing interoperation between it and our own system.
  class LMS

    public

    # Creates a user in canvas based on the passed user
    # storing the new canvas user id in the object.
    #
    # Be sure to call user.save at some point after using this.
    def create_user(user)
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
        'pseudonym[unique_id]' => user.email,
        'pseudonym[send_confirmation]' => false,
        'communication_channel[skip_confirmation]' => true,
        'communication_channel[confirmation_url]' => true,
        'pseudonym[sis_user_id]' => user_student_id
      )
      response = @canvas_http.request(request)

      new_canvas_user = JSON.parse response.body

      # this will be set if we actually created a new user
      # reasons why it might fail would include existing user
      # already having the email address

      # Not necessarily an error but for now i'll just make it throw
      raise "Couldn't create user #{user.email} in canvas #{response.body}" if new_canvas_user['id'].nil?

      user.canvas_user_id = new_canvas_user['id']

      if new_canvas_user['confirmation_url']
          request = Net::HTTP::Get.new(new_canvas_user['confirmation_url'])
          @canvas_http.request(request)
      end

      user
    end

    # Looks up the user in canvas, setting the ID locally if found,
    # and creating the user on Canvas if not.
    #
    # Don't forget to call user.save after using this.
    def sync_user_logins(user)
      canvas_user = find_user(user.email)
      if canvas_user.nil?
        create_user(user)
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
      info = JSON.parse response.body

      info
    end

    # Returns an array of enrollments objects for the course.
    # https://canvas.instructure.com/doc/api/enrollments.html
    def get_course_enrollments(course_id)
      open_canvas_http

      request = Net::HTTP::Get.new(
        "/api/v1/courses/#{course_id}/enrollments?access_token=#{Rails.application.secrets.canvas_access_token}"
      )
      response = @canvas_http.request(request)
      info = JSON.parse response.body

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

    private

    def read_sections(course_id)
      if @section_info.nil?
        @section_info = {}
      end

      if @section_info[course_id].nil?
        @section_info[course_id] = {}

        open_canvas_http

        request = Net::HTTP::Get.new(
          "/api/v1/courses/#{course_id}/sections?access_token=#{Rails.application.secrets.canvas_access_token}"
        )
        response = @canvas_http.request(request)
        info = JSON.parse response.body

        info.each do |section|
          @section_info[course_id][section['name']] = section
        end
      end

      @section_info[course_id]
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
