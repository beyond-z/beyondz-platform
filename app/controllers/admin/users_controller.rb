require 'csv'

require 'lms'

class Admin::UsersController < Admin::ApplicationController
  def index
    current_page = params[:page] # was getting ArgumentError (wrong number of arguments (1 for 0) when using param directly with .page method
    if params[:search]
      @users = User.search(params[:search]).page(current_page)
    else
      @users = User.order(:last_name).page(current_page)
    end
    respond_to do |format|
      format.html { render }
      format.csv { render text: csv_export }
      format.xls { send_data(@users.to_xls) }
    end
  end

  # The lead owner mapping is a user-configurable setup that maps
  # new leads (people who just signed up on the website) to an owner -
  # a staff member who is responsible for contacting that person and
  # guiding them through any next steps.
  #
  # It is used on Salesforce and could also be used for other customer
  # relationship management tasks
  def lead_owner_mapping
    respond_to do |format|
      format.csv { render text: csv_lead_owner_export }
    end
  end

  def canvas_page_views
    # render a simple view
  end

  def get_canvas_page_views
    initialize_lms_interop
    @lms.delay.email_user_data_spreadsheet(params[:email], params[:course_id])
  end

  # It should change to Lead_owner, applicant_type, university_name, bz_region
  # and allow blanks on them.
  def csv_lead_owner_export
    CSV.generate do |csv|
      header = []
      header << 'Lead_owner'
      header << 'Applicant type'
      header << 'University Name'
      header << 'Braven Region'

      csv << header

      LeadOwnerMapping.all.each do |m|
        exportable = []
        exportable << m.lead_owner
        exportable << m.applicant_type
        exportable << m.university_name
        exportable << m.bz_region

        csv << exportable
      end
    end
  end

  def import_lead_owner_mapping
    # just rendering a view...
  end

  def do_import_lead_owner_mapping
    if params[:import].nil?
      flash[:message] = 'Please upload a csv file'
      redirect_to admin_import_lead_owner_mapping_path
      return
    end

    file = CSV.parse(params[:import][:csv].read)
    LeadOwnerMapping.destroy_all
    file.each do |row|
      LeadOwnerMapping.create(
        :lead_owner => row[0],
        :applicant_type => row[1],
        :university_name => row[2],
        :bz_region => row[3]
      )
    end
  end

  def campaign_mapping
    # render a view
  end

  def do_campaign_mapping
    if params[:import].nil?
      flash[:message] = 'Please upload a csv file'
      redirect_to admin_campaign_mapping_path
      return
    end

    file = CSV.parse(params[:import][:csv].read)
    CampaignMapping.destroy_all
    file.each do |row|
      CampaignMapping.create(
        :campaign_id => row[0],
        :applicant_type => row[1],
        :university_name => row[2],
        :bz_region => row[3]
      )
    end
  end

  def bulk_student_upload
    # render a view
  end

  def do_bulk_student_upload
    if params[:import].nil?
      flash[:message] = 'Please upload a csv file'
      redirect_to admin_bulk_student_upload_path
      return
    end

    file = CSV.parse(params[:import][:csv].read)

    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')

    file.each do |row|
      # set the relevant variables on salesforce
      if row[10] == 'Y' && row[11] == 'Y' # Received Code (Y/N) and Enrolled in Class?
        email = row[6]
        u = User.find_by_email(email)
        if u
          cm = SFDC_Models::CampaignMember.find_by_ContactId(u.salesforce_id)
          if cm
            cm.Section_Name_In_LMS__c = row[13]
            cm.Candidate_Status__c = 'Confirmed'
            cm.save
          end
        end
      end
    end

    flash[:message] = 'Upload successful'
    redirect_to admin_bulk_student_upload_path
  end


  def update
    initialize_lms_interop

    @user = User.find(params[:id])

    old_email = @user.email

    if params[:user][:email] && params[:user][:email] != old_email
      new_email = params[:user][:email]

      # Update this database
      @user.email = new_email
      @user.skip_reconfirmation!

      # Update Salesforce
      if @user.salesforce_id
        salesforce = BeyondZ::Salesforce.new
        client = salesforce.get_client
        client.materialize('Contact')

        contact = SFDC_Models::Contact.find(@user.salesforce_id)
        if contact
          contact.Email = new_email
          contact.save
        end
      end

      # Update Canvas
      if @user.canvas_user_id
        @lms.change_user_email(@user.canvas_user_id, old_email, new_email)
      end
    end

    @user.first_name = params[:user][:first_name] unless params[:user][:first_name].nil?
    @user.last_name = params[:user][:last_name] unless params[:user][:last_name].nil?
    @user.salesforce_id = params[:user][:salesforce_id] unless params[:user][:salesforce_id].nil?
    @user.password = params[:user][:password] unless params[:user][:password].nil? || params[:user][:password].empty?

    if params[:sync_with_canvas]
      @lms.sync_user_logins(@user)
    end

    @user.save!
    redirect_to "/admin/users/#{@user.id}"
  end

  def impersonate
    sign_in(:user, User.find(params[:id]))
    if params[:unsubmit_application]
      enrollment = Enrollment.find_by_user_id(params[:id])
      if enrollment
        enrollment.explicitly_submitted = false
        enrollment.save(validate: false)
        # Also send them straight there as that's probably what we actually
        # want to do.
        redirect_to enrollment_path(enrollment.id)
      else
        # No enrollment to reset
        redirect_to root_path
      end
    else
      redirect_to root_path
    end
  end

  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def find_by_salesforce_id
    @user = User.find_by_salesforce_id(params[:id])
    render 'show'
  end

  def enroll_by_salesforce_id
    @user = User.find_by_salesforce_id(params[:id])
    @action = 'Enroll the user as a student'
    render 'confirm'
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


    # Save first so it gets an id
    @user.save!

    # then sync with canvas (it needs to know the id first to have
    # a unique sis id)
    if params[:sync_with_canvas]
      @lms.sync_user_logins(@user)
      # and save again so it stores the lms user ID in the object
      @user.save!
    end


    redirect_to admin_users_path
  end

  def user_status_csv_import
    # form to accept a csv file that has user ids and assigned owner
  end

  # this little spreadsheet has user_id, exclude_from_reporting, relationship_manager, program
  # only rows present in the spreadsheet are modified when imported
  def do_user_status_csv_import
    if params[:import].nil?
      flash[:message] = 'Please upload a csv file'
      redirect_to admin_user_status_csv_import_path
      return
    end
    file = CSV.parse(params[:import][:csv].read)
    @failures = []
    file.each do |row|
      user_id = row[0]
      # If the user id isn't actually a number, skip this row
      # because that means it is probably a header or a blank line
      # http://stackoverflow.com/questions/10577783/ruby-checking-if-a-string-can-be-converted-to-an-integer
      begin
        user_id = Integer user_id
      rescue
        next
      end

      begin
        user = User.find(user_id)
        user.exclude_from_reporting = row[1]
        user.relationship_manager = row[2]
        user.associated_program = row[3]
        user.active_status = row[4]
        user.save!
      rescue
        @failures << user_id
      end
    end
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
    # We have three K-12 columns: epapa (3), and nyc (1)
    # At this time, a person can only possibly be a participant in one
    # city, so we look for the one that isn't nil. If all are nil, they
    # aren't a K-12 participant at all.
    possible_k12_columns = [1, 3]

    # we don't want it to be nil, so set it to the first possibility
    k12_column = possible_k12_columns[0]
    # then scan all columns until we hit one that is actually used
    # (or if none are used, we'll use the first option of 'none' below
    possible_k12_columns.each do |c|
      unless row[c].nil? || row[c] == 'none'
        k12_column = c
        break
      end
    end
    # There's three college programs now: sjsu, nyc, and dc
    possible_college_columns = [5, 7, 9]
    college_column = possible_college_columns[0]
    possible_college_columns.each do |c|
      unless row[c].nil? || row[c] == 'none'
        college_column = c
        break
      end
    end

    # This really needs refactoring. Column 5 is SJSU. It gets
    # the course #2. The others, NYC and DC, get the 4 week course.
    college_course = college_column == 5 ? 2 : 9

    # The column right next to the role is always the cohort
    k12_role = row[k12_column]
    k12_cohort = row[k12_column + 1]

    college_role = row[college_column]
    college_cohort = row[college_column + 1]

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

    if college_role == 'student' || college_role == 'peeradvisor'
      accelerator = 'STUDENT'
      section_accelerator = college_cohort
    elsif college_role == 'coach'
      accelerator = 'TA'
      section_accelerator = college_cohort

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
    @lms.sync_user_course_enrollment(@user, college_course, accelerator, section_accelerator)

    @user.save!
  end

  def csv_export_header
    header = []
    header << 'User ID'
    header << 'First Name'
    header << 'Last Name'
    header << 'Email'
    header << 'Relationship Manager (owner)'
    header << 'New User'
    header << 'Days Since Last Activity'
    header << 'Exclude from reporting'
    header << 'Active Status'
    header << 'Applicant type'
    header << 'Type = other'
    header << 'Anticipated Graduation'
    header << 'Started College In'
    header << 'University Name'
    header << 'Braven Region(s)'
    header << 'Profession/Title/Industry'
    header << 'Company'
    header << 'City'
    header << 'State'
    header << 'Like to know when BV starts program'
    header << 'Like to help BV start'
    header << 'User-provided comments'
    header << 'Signup Date'
    header << 'Last sign in at'
    header << 'Came from to reach site'
    header << 'Came from to reach sign up form'
    header << 'Associated Program'

    Enrollment.column_names.each do |cn|
      header << cn
    end

    header << 'Resume URL'

    header
  end

  def csv_export
    CSV.generate do |csv|
      csv << csv_export_header
      @users.each do |user|
        exportable = []

        exportable << user.id
        exportable << user.first_name
        exportable << user.last_name
        exportable << user.email
        exportable << user.relationship_manager
        exportable << !user.relationship_manager?
        exportable << user.days_since_last_activity
        exportable << user.exclude_from_reporting
        exportable << user.active_status
        exportable << user.applicant_type
        exportable << user.applicant_details
        exportable << user.anticipated_graduation
        exportable << user.started_college_in
        exportable << user.university_name
        exportable << user.bz_region
        exportable << user.profession
        exportable << user.company
        exportable << user.city
        exportable << user.state
        exportable << user.like_to_know_when_program_starts
        exportable << user.like_to_help_set_up_program
        exportable << user.applicant_comments
        exportable << user.created_at.to_s
        exportable << user.last_sign_in_at.to_s
        exportable << user.external_referral_url
        exportable << user.internal_referral_url
        exportable << user.associated_program

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
