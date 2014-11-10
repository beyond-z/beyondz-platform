require 'csv'

require 'lms'

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

    initialize_lms_interop

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

      # if @user.canvas_user_id.nil?
      #   @lms.create_user(@user)
      # end

      @user.save!
    end
    unless params[:user][:declined_from_program].nil?
      @user.fast_tracked = params[:user][:declined_from_program]
      # send email here saying try again next time
    end

    @user.first_name = params[:user][:first_name] unless params[:user][:first_name].nil?
    @user.last_name = params[:user][:last_name] unless params[:user][:last_name].nil?
    @user.password = params[:user][:password] unless params[:user][:password].nil? || params[:user][:password].empty?

    if params[:sync_with_canvas]
      @lms.sync_user_logins(@user)
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

  def edit
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy!
    redirect_to '/admin/users'
  end

  def create
    initialize_lms_interop

    @user = User.new(params[:user].permit(
      :first_name, :last_name, :email, :password))
    @user.skip_confirmation! # admins don't need to confirm new accounts
    raise @user.errors.to_json unless @user.valid?


    if params[:sync_with_canvas]
      @lms.sync_user_logins(@user)
    end

    @user.save!

    redirect_to admin_users_path
  end

  def csv_import
    # renders a form
  end

  def do_csv_import
    initialize_lms_interop

    @failed_imports = []

    file = CSV.parse(params[:import][:csv].read)
    row_number = 0
    file.each do |row|
      row_number += 1
      if row_number == 1
        next # skip header
      end

      email = row[0]
      next if email.nil? || email.empty? || email == 'Email' # skip header too

      # The find_by seems to be case-sensitive, and we want to ignore case
      # easiest way is to just standardize the search by using lower case everywhere
      email = email.downcase

      process_imported_row(row, email)
    end
  end

  private

  # Creates @lms, a wrapper class for communicating with and caching results
  # from the Canvas LMS
  def initialize_lms_interop
    if @lms.nil?
      @lms = BeyondZ::LMS.new
    end
  end

  def process_imported_row(row, email)
    is_nyc = (row[3].nil? || row[3] == 'none') # If not assigned in epapa, use NYC as K-12 column
    k12_role = is_nyc ? row[1] : row[3]
    k12_cohort = is_nyc ? row[2] : row[4]
    sjsu_role = row[5]
    sjsu_cohort = row[6]

    coaching_beyond = nil
    overdrive = nil
    accelerator = nil

    section_overdrive = nil
    section_accelerator = nil

    # This is K-12
    if k12_role == 'student' || k12_role == 'peeradvisor'
      # Nothing - K-12 students aren't imported
    elsif k12_role == 'coach'
      overdrive = 'STUDENT'
      section_overdrive = k12_cohort
    end

    if sjsu_role == 'student' || sjsu_role == 'peeradvisor'
      accelerator = 'STUDENT'
      section_accelerator = sjsu_cohort
    elsif sjsu_role == 'coach'
      # accelerator = 'TA'
      section_accelerator = sjsu_cohort

      coaching_beyond = 'STUDENT'
      section_coaching_beyond = 'acceleratorlc'
    end

    @user = User.find_by(:email => email)

    if @user.nil?
      @failed_imports << email
      return
    end

    initialize_lms_interop

    @lms.sync_user_logins(@user)

    @lms.sync_user_course_enrollment(@user, 7, coaching_beyond, section_coaching_beyond)
    @lms.sync_user_course_enrollment(@user, 3, overdrive, section_overdrive)
    @lms.sync_user_course_enrollment(@user, 2, accelerator, section_accelerator)

    @user.save!
  end

  def csv_export
    CSV.generate do |csv|
      header = []
      header << 'First Name'
      header << 'Last Name'
      header << 'Email'
      header << 'New Since Last'
      header << 'Days Since Last'
      header << 'Applicant type'
      header << 'Anticipated Graduation'
      header << 'City'
      header << 'State'
      header << 'Applicant details'
      header << 'University Name'
      header << 'Signup Date'
      header << 'Last sign in at'
      header << 'Subscribed to Email'
      header << 'Came from to reach site'
      header << 'Came from to reach sign up form'
      header << 'Interested joining'
      header << 'Interested partnering'
      header << 'Interested receiving'

      Enrollment.column_names.each do |cn|
        header << cn
      end

      csv << header
      @users.each do |user|
        exportable = []
        exportable << user.first_name
        exportable << user.last_name
        exportable << user.email
        exportable << !user.has_owner?
        exportable << user.days_since_last_appeared
        exportable << user.applicant_type
        exportable << user.anticipated_graduation
        exportable << user.city
        exportable << user.state
        exportable << user.applicant_details
        exportable << user.university_name
        exportable << user.created_at.to_s
        exportable << user.last_sign_in_at.to_s
        exportable << user.keep_updated
        exportable << user.external_referral_url
        exportable << user.internal_referral_url
        exportable << user.interested_joining
        exportable << user.interested_partnering
        exportable << user.interested_receiving

        if user.enrollment
          e = user.enrollment
          e.attributes.values_at(*Enrollment.column_names).each do |v|
            exportable << v
          end

          if e.resume.present?
            exportable << e.resume.url
          else
            exportable << '<none uploaded>'
          end
        end

        csv << exportable
      end
    end
  end
end
