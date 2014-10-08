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
        'pseudonym[send_confirmation]' => false
      )
      response = @canvas_http.request(request)

      new_canvas_user = JSON.parse response.body

      # this will be set if we actually created a new user
      # reasons why it might fail would include existing user
      # already having the email address

      # Not necessarily an error but for now i'll just make it throw
      raise "Couldn't create user #{user.email} in canvas #{response.body}" if new_canvas_user['id'].nil?

      user.canvas_user_id = new_canvas_user['id']

      user
    end

    # Looks up the user in canvas, setting the ID locally if found,
    # and creating the user on Canvas if not.
    #
    # Don't forget to call user.save after using this.
    def sync_user(user)
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
