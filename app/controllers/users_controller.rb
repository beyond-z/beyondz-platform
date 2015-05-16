class UsersController < ApplicationController

  layout 'public'

  before_filter :authenticate_user!, :only => [:reset, :confirm, :save_confirm, :not_on_lms]

  # Our LMS sends logged in, but non-existent (on that application) users
  # back here for us to handle. We need to identify them and send them
  # back to the right place
  def not_on_lms
    if current_user.is_administrator?
      redirect_to admin_root_path
    elsif current_user.in_lms?
      # They came from the LMS as non-existent, but we think they're in it
      # something is wrong, either our databases are out of sync or the
      # user was deleted or something

      # Let's notify the tech team of the strange situation, then send
      # the user to the generic welcome path

      StaffNotifications.lms_mismatch(current_user).deliver

      redirect_to welcome_path
    else
      # everyone else can just go to welcome to get a generic hello
      redirect_to welcome_path
    end
  end

  # We need to exempt this from csrf checking so the CAS server can
  # POST to it. While the operation is theoretically suitable for GET,
  # POST keeps information from appearing in the server logs.
  skip_before_filter :verify_authenticity_token, :only => [:check_credentials]

  # This is present to allow an external single sign on server to
  # authenticate users against our main database. Allows better
  # integration with the Canvas LMS via RubyCAS at present.
  def check_credentials
    user = User.find_for_database_authentication(:email => params[:username])
    if user.nil?
      valid = false
    else
      # Without checking user.confirmed, this would allow SSO to authenticate,
      # but Devise would still kick them back to SSO as they are inactive and
      # should try a different account... leading to an infinite loop.
      #
      # Unconfirmed accounts are never able to log in until they confirm.
      valid = user.confirmed? && user.valid_password?(params[:password])
    end

    respond_to do |format|
      format.json { render json: valid }
    end
  end

  def confirm
    # If they are already confirmed and accepted, here refreshing the page
    # to watch for updates perhaps, we want to send them to where they want
    # to be - canvas - ASAP.
    if current_user.in_lms?
      redirect_to "//#{Rails.application.secrets.canvas_server}/"
    end
    # renders a view
  end

  def save_confirm
    current_user.program_attendance_confirmed = true
    current_user.save!

    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')
    client.materialize('Contact')
    cm = SFDC_Models::CampaignMember.find_by_ContactId(current_user.salesforce_id)
    if cm
      cm.Candidate_Status__c = 'Confirmed'
      cm.Apply_Button_Enabled__c = false
      cm.save
    end

    contact = SFDC_Models::Contact.find(current_user.salesforce_id)
    if contact
      case current_user.applicant_type
      when 'undergrad_student'
        contact.Participant_Information__c = 'Participant'
      when 'volunteer'
        contact.Volunteer_Information__c = 'Current LC'
      else
        # this space intentionally left blank
        # because other shouldn't be confirmed through
        # this controller anyway, but if they do link,
        # we don't want to crash - we can still update
        # our local database.
      end

      contact.save
    end



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

  # This is meant to enable a forced logout from the SSO server, to keep
  # users sane across different applications. Without something like this,
  # logging out of say, Canvas, will do it and SSO... but won't clear the
  # bz.org cookie, so if the user goes back there, they'll show up possible
  # as a different user, confusing them.
  #
  # This has the potential risk of denial-of-service. The check of the referrer
  # coming from the SSO domain is meant to provide some protection against
  # random image tags (for example) on other sites logging you out, but it
  # isn't a perfect solution. Alas, I'm not sure there can be a perfect
  # solution. Maybe a complex cryptographically signed thing, but meh, I don't
  # think the risk is that big. The referrer check should foil any pranks
  # in practice.
  def clear_session_cookie
    if request.referer.starts_with?(Rails.application.secrets.sso_url)
      reset_session
    end
    render nothing: true
  end

  def new
    states
    @referrer = request.referrer
    @user = User.new
    @user.applicant_type = params[:applicant_type] if params[:applicant_type]
    @user.university_name = params[:university_name] if params[:university_name]
    if params[:applicant_type]
      @hide_other_applicant_types = true
    end
  end

  def create
    user = params[:user].permit(
      :first_name,
      :last_name,
      :email,
      :password,

      :phone,

      :applicant_type,
      :applicant_details,
      :applicant_comments,
      :bz_region,
      :university_name,
      :like_to_know_when_program_starts,
      :like_to_help_set_up_program,
      :started_college_in,
      :anticipated_graduation,
      :profession,
      :company,
      :city,
      :state)

    user[:external_referral_url] = session[:referrer] # the first referrer saw by the app
    user[:internal_referral_url] = params[:referrer] # the one that led direct to sign up
    @referrer = params[:referrer] # preserve the original one in case of error

    user[:university_name] = params[:undergrad_university_name] if user[:university_name] == 'other'

    if !user[:applicant_type].nil?
      @new_user = User.new(user)
      unless user[:applicant_type] == 'undergrad_student' || user[:applicant_type] == 'volunteer'
        # Partners, employers, and others are reached out to manually instead of confirming
        # their account. We immediate make on salesforce and don't require confirmation so
        # we can contact them quickly and painlessly (to them!).
        @new_user.skip_confirmation!
      end

      # FIXME: hack to avoid email activation for signups mapped to active campaigns.  this is to get
      # around the fact that activation emails are going to spam.  uncomment once we can send emails again.
      if @new_user.salesforce_campaign_id
        @new_user.skip_confirmation!
      end

      @new_user.save
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

    @new_user.create_on_salesforce

    if @new_user.salesforce_campaign_id
      # FIXME: hack, this auto-signs in users that are mapped to active campaign since we skip confirmation
      # so they can immediately apply.  This is because our emails are going to spam.  Once
      # that is fixed, undo this.
      sign_in('user', @new_user)
    end

    redirect_to redirect_to_welcome_path(@new_user)

    StaffNotifications.new_user(@new_user).deliver
  end

  private

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
