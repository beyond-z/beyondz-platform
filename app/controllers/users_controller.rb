class UsersController < ApplicationController

  layout 'public'

  before_filter :authenticate_user!, :only => [:reset, :confirm, :save_confirm]

  def check_credentials
    user = User.find_for_database_authentication(:email=>params[:username])
    if user.nil?
      valid = false
    else
      valid = user.valid_password?(params[:password])
    end

    respond_to do |format|
      format.json { render json: valid }
    end
  end

  def confirm
    # renders a view
  end

  def save_confirm
    current_user.program_attendance_confirmed = true
    current_user.save!
    redirect_to user_confirm_path
  end

  def reset
    u = current_user

    # only want this to happen on test users
    # via the web interface to protect production data
    if u.email.starts_with?('test+')
      u.reset_assignments!
    end

    redirect_to root_path
  end

  def new
    states
    @referrer = request.referrer
    @user = User.new
  end

  def create
    user = params[:user].permit(
      :first_name,
      :last_name,
      :email,
      :password,
      :applicant_type,
      :city,
      :state,
      :interested_joining,
      :interested_receiving,
      :interested_partnering,
      :keep_updated)

    user[:external_referral_url] = session[:referrer] # the first referrer saw by the app
    user[:internal_referral_url] = params[:referrer] # the one that led direct to sign up
    @referrer = params[:referrer] # preserve the original one in case of error

    if !user[:applicant_type].nil?
      populate_user_details user
      @new_user = User.create(user)
    else
      # this is required when signing up through this controller,
      # but is not necessarily required for all users - e.g. admin
      # users aren't an applicant so we don't want this in the model
      @new_user = User.new(user)
      @new_user.errors[:applicant_type] = 'must be chosen from the list'
    end

    if @new_user.errors.any?
      states
      @user = @new_user
      render 'new'
      return
    end

    unless @new_user.id
      # If User.create failed without errors, we have an existing user
      flash[:message] = 'You have already joined us, please log in.'
      redirect_to new_user_session_path
      return
    end

    redirect_to redirect_to_welcome_path(@new_user)
  end

  private

  def populate_user_details(user)
    case user[:applicant_type]
    when 'other'
      user[:applicant_details] = params[:other_details]
    when 'professional'
      user[:applicant_details] = params[:professional_details]
    when 'grad_student'
      # Each of these has different names in the form to ensure no data
      # conflict as the user explores the bullets, but they all map to
      # the same database field since it is really the same data
      user[:anticipated_graduation] = params[:anticipated_grad_graduation]
      user[:university_name] = params[:grad_university_name]
    when 'undergrad_student'
      user[:anticipated_graduation] = params[:anticipated_undergrad_graduation]
      user[:university_name] = params[:undergrad_university_name]
    when 'school_student'
      user[:anticipated_graduation] = 'Grade ' + params[:grade]
    end

  end

  def states
    @states = {
      'Alabama' => 'AL', 'Alaska' => 'AK', 'Arizona' => 'AZ',
      'Arkansas' => 'AR', 'California' => 'CA', 'Colorado' => 'CO',
      'Connecticut' => 'CT', 'Delaware' => 'DE', 'District of Columbia' => 'DC',
      'Florida' => 'FL', 'Georgia' => 'GA', 'Hawaii' => 'HI', 'Idaho' => 'ID',
      'Illinois' => 'IL', 'Indiana' => 'IN', 'Iowa' => 'IA', 'Kansas' => 'KS',
      'Kentucky' => 'KY', 'Louisiana' => 'LA', 'Maine' => 'ME', 'Maryland' => 'MD',
      'Massachusetts' => 'MA', 'Michigan' => 'MI', 'Minnesota' => 'MN',
      'Mississippi' => 'MS', 'Missouri' => 'MO', 'Montana' => 'MT',
      'Nebraska' => 'NE', 'Nevada' => 'NV', 'New Hampshire' => 'NH',
      'New Jersey' => 'NJ', 'New Mexico' => 'NM', 'New York' => 'NY',
      'North Carolina' => 'NC', 'North Dakota' => 'ND', 'Ohio' => 'OH',
      'Oklahoma' => 'OK', 'Oregon' => 'OR', 'Pennsylvania' => 'PA',
      'Rhode Island' => 'RI', 'South Carolina' => 'SC', 'South Dakota' => 'SD',
      'Tennessee' => 'TN', 'Texas' => 'TX', 'Utah' => 'UT', 'Vermont' => 'VT',
      'Virginia' => 'VA', 'Washington' => 'WA', 'West Virginia' => 'WV',
      'Wisconsin' => 'WI', 'Wyoming' => 'WY'
    }
  end
end
