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
        # create_canvas_user
      # end

      # and enroll me in the proper course (#2 is bz test right now)
      # request = Net::HTTP::Post.new('/api/v1/courses/2/enrollments') # FIXME: hard coded course number
      # request.set_form_data(
        # 'access_token' => Rails.application.secrets.canvas_access_token,
        # 'enrollment[user_id]' => @user.canvas_user_id,
        # 'enrollment[type]' => 'StudentEnrollment',
        # 'enrollment[enrollment_state]' => 'active',
        # 'enrollment[notify]' => false
      # )
      # @canvas_http.request(request)

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

  private

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
      raise 'Couldn\'t create user in canvas'
    end

    @user.canvas_user_id = new_canvas_user['id']
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
