require 'csv'

class Admin::UsersController < Admin::ApplicationController
  def index
    @users = User.all
    respond_to do |format|
      format.html { render }
      format.csv { render text: csv_export }
      format.xls { send_data(@users.to_xls) }
    end
  end

  def update
    @user = User.find(params[:id])
    unless params[:user][:fast_tracked].nil?
      @user.fast_tracked = params[:user][:fast_tracked]
    end
    unless params[:user][:availability_confirmation_requested].nil?
      @user.availability_confirmation_requested = params[:user][:availability_confirmation_requested]
      # Commented mailer right now because the team is doing this manually
      # via mail merge.
      # AcceptanceMailer.request_availability_confirmation(@user).deliver
    end
    unless params[:user][:accepted_into_program].nil?
      @user.accepted_into_program = params[:user][:accepted_into_program]

      # This is commented pending finalization of the design
      # from the team.

      # Create the canvas user
      # open_canvas_http

      # if @user.canvas_user_id.nil?
      #   create_canvas_user
      # end

      @user.save!
    end
    unless params[:user][:declined_from_program].nil?
      @user.fast_tracked = params[:user][:declined_from_program]
      # send email here saying try again next time
    end
    @user.save!
    redirect_to "/admin/users/#{@user.id}"
  end

  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy!
    redirect_to '/admin/users'
  end

  def create
    @user = User.new(params[:user].permit(
      :first_name, :last_name, :email, :password))
    @user.skip_confirmation! # admins don't need to confirm new accounts
    @user.save!
    redirect_to admin_users_path
  end

  def csv_import
    # renders a form
  end

  def do_csv_import
    file = CSV.parse(params[:import][:csv].read)
    row_number = 0
    open_canvas_http
    file.each do |row|
      row_number += 1
      if row_number == 1
        next # skip header
      end

      email = row[0]
      if email.empty?
        next
      end

      process_imported_row(row)
    end
  end

  private

  def process_imported_row(row)
    epapa_role = row[1]
    epapa_cohort = row[2]
    sjsu_role = row[3]
    sjsu_cohort = row[4]

    coaching_beyond = nil
    overdrive = nil
    accelerator = nil

    section_coaching_beyond = nil
    section_overdrive = nil
    section_accelerator = nil

    # This is K-12
    if epapa_role == 'student' || epapa_role == 'peeradvisor'
      overdrive = 'STUDENT'
      section_overdrive = epapa_cohort
    elsif epapa_role == 'coach'
      overdrive = 'TA'
      section_overdrive = epapa_cohort

      coaching_beyond = 'STUDENT'
      section_coaching_beyond = 'overdrivebayarea'
    end

    if sjsu_role == 'student' || sjsu_role == 'peeradvisor'
      accelerator = 'STUDENT'
      section_accelerator = sjsu_cohort
    elsif sjsu_role == 'coach'
      accelerator = 'TA'
      section_accelerator = sjsu_cohort

      coaching_beyond = 'STUDENT'
      section_coaching_beyond = 'acceleratorlc'
    end

    @user = User.find_by(:email => email)
    # This should never be needed in production because they applied through this system!
    create_imported_user(email) if @user.nil?

    create_canvas_user if @user.canvas_user_id.nil?

    enroll_user_in_course(7, coaching_beyond, section_coaching_beyond)
    enroll_user_in_course(3, overdrive, section_overdrive)
    enroll_user_in_course(2, accelerator, section_accelerator)

    @user.save!
  end

  def create_imported_user(email)
    @user = User.new(
      :first_name => email,
      :last_name => 'Imported',
      :email => email,
      :password => 'test'
    )
    @user.skip_confirmation!
    @user.save!
  end

  def csv_export
    CSV.generate do |csv|
      header = Array.new
      header << 'First Name'
      header << 'Last Name'
      header << 'Email'
      header << 'Type'
      header << 'Details'
      header << 'Anticipated Graduation'
      header << 'University Name'
      header << 'Signup Date'
      header << 'Subscribed to Email'
      header << 'Came from to reach site'
      header << 'Came from to reach sign up form'
      csv << header
      @users.each do |user|
        exportable = Array.new
        exportable << user.first_name
        exportable << user.last_name
        exportable << user.email
        exportable << user.applicant_type
        exportable << user.applicant_details
        exportable << user.anticipated_graduation
        exportable << user.university_name
        exportable << user.created_at.to_s
        exportable << user.keep_updated
        exportable << user.external_referral_url
        exportable << user.internal_referral_url
        csv << exportable
      end
    end
  end

  # Creates a user in canvas based on the currently loaded @user,
  # storing the new canvas user id in the object.
  #
  # Be sure to call @user.save at some point after using this.
  def create_canvas_user
    open_canvas_http

    # the v1 is API version, only one option available in Canvas right now
    # accounts/1 refers to the Beyond Z account, which is the only one
    # we use since it is a custom installation.
    request = Net::HTTP::Post.new('/api/v1/accounts/1/users')
    request.set_form_data(
      'access_token' => Rails.application.secrets.canvas_access_token,
      'user[name]' => @user.name,
      'user[short_name]' => @user.first_name,
      'user[sortable_name]' => "#{@user.last_name}, #{@user.first_name}",
      'user[terms_of_use]' => true,
      'pseudonym[unique_id]' => @user.email,
      'pseudonym[send_confirmation]' => false
    )
    response = @canvas_http.request(request)

    new_canvas_user = JSON.parse response.body

    # this will be set if we actually created a new user
    # reasons why it might fail would include existing user
    # already having the email address

    # Not necessarily an error but for now i'll just make it throw
    if new_canvas_user['id'].nil?
      raise "Couldn't create user #{@user.email} in canvas #{response.body}"
    end

    @user.canvas_user_id = new_canvas_user['id']
  end

  def enroll_user_in_course(course_id, role, section)
    if role.nil?
      return
    end

    open_canvas_http

    role = role.capitalize

    request = Net::HTTP::Post.new("/api/v1/courses/#{course_id}/enrollments")
    data = {
      'access_token' => Rails.application.secrets.canvas_access_token,
      'enrollment[user_id]' => @user.canvas_user_id,
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

  def read_sections(course_id)
    if @section_info.nil?
      @section_info = {}
    end

    if @section_info[course_id].nil?
      @section_info[course_id] = {}

      open_canvas_http

      request = Net::HTTP::Get.new("/api/v1/courses/#{course_id}/sections")
      response = @canvas_http.request(request)
      info = JSON.parse response.body

      info.each do |section|
        @section_info[course_id][section['name']] = info
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
