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

  def prep_confirm_campaign_info
    # These should never be nil at this point, so I'm not checking
    # it - if it does happen, the error report should help us find
    # why it was nil and fix that root cause bug.

    # Both @enrollment and campaign should never be nil.

    @enrollment = Enrollment.find_by(:user_id => current_user.id)

    if @enrollment.nil?
      redirect_to welcome_path
      return
    end

    @confirmation_type = @enrollment.position

    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('Campaign')
    campaign = SFDC_Models::Campaign.find(@enrollment.campaign_id)

    if campaign
      @program_title = campaign.Program_Title__c
      @program_site = campaign.Program_Site__c
      @request_availability = campaign.Request_Availability__c
      @meeting_times = campaign.Meeting_Times__c

      # An SOQL query is the most efficient way to get up-to-date information -
      # it will aggregate the cohorts on the server in a single request.

      # However, the client.query method wants to return SObjects which don't support
      # sql aggregation features. So, we must use the lower level http_get method ourselves
      # to get at the underlying data.
      query_result = client.http_get("/services/data/v#{client.version}/query?q=" \
        "SELECT COUNT(ContactId), Selected_Timeslot__c FROM CampaignMember WHERE CampaignId = '#{campaign.Id}' AND Candidate_Status__c = 'Confirmed' GROUP BY Selected_Timeslot__c")

      sf_answer = JSON.parse(query_result.body)

      used_slots_map = {}
      sf_answer['records'].each do |record|
        record_count = record['expr0']
        record_section = record['Selected_Timeslot__c']

        used_slots_map[record_section] = record_count
      end

      @times = []

      # We now need to format the meeting times and determine
      # if there's any free slots. This is done by querying the
      # actual users. Might want to cache this later and do triggers
      # but for now I want to try this for best possible accuracy
      # (though there's still a potential race condition...)
      @meeting_times.lines.map(&:strip).each_with_index do |line, index|
        
        idx = line.rindex(':')
        if idx
          time = line[0 .. idx-1]
          total_slots = line[idx + 1 .. -1].strip.to_i

          used_slots = 0
          unless used_slots_map[time].nil?
            used_slots = used_slots_map[time]
          end

          info = {}
          info['time'] = time
          info['total_slots'] = total_slots
          info['slots'] = total_slots - used_slots
          info['id'] = index

          @times.push(info)
        end
      end
    end

  end

  def confirm
    # If they are already confirmed and accepted, here refreshing the page
    # to watch for updates perhaps, we want to send them to where they want
    # to be - canvas - ASAP.
    if current_user.in_lms?
      redirect_to "//#{Rails.application.secrets.canvas_server}/"
    else
      prep_confirm_campaign_info
    end

    # renders a view
  end

  # After they select a time slot, they are asked to "make it official"
  # or to self-waitlist. This method handles that.
  def confirm_part_2
    prep_confirm_campaign_info

    if params[:time] == 'none'
      # the view handles it because there is
      # no selected time.
    else
      @selected_time = @times[params[:time].to_i]['time']
    end
  end

  def save_confirm
    current_user.program_attendance_confirmed = true
    current_user.save!

    # These are actually filled in by the campaign inside a couple ifs
    program_title = 'Braven'
    program_site = ''

    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')
    client.materialize('Contact')

    @enrollment = Enrollment.find_by(:user_id => current_user.id)

    cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(current_user.salesforce_id, @enrollment.campaign_id)
    if cm
      cm.Candidate_Status__c = params[:selected_time] ? 'Confirmed' : 'Waitlisted'
      cm.Selected_Timeslot__c = params[:selected_time] ? params[:selected_time] : params[:times].join(';')

      # Set the section name automatically according to the pattern..
      # This is only for coaches. Students are manually mapped to cohorts.
      if current_user.applicant_type == 'volunteer'
        client.materialize('Campaign')
        campaign = SFDC_Models::Campaign.find(@enrollment.campaign_id)

        name = params[:selected_time]

        name = 'Su' if name.match(/sunday/i)
        name = 'Mo' if name.match(/monday/i)
        name = 'Tu' if name.match(/tuesday/i)
        name = 'We' if name.match(/wednesday/i)
        name = 'Th' if name.match(/thursday/i)
        name = 'Fr' if name.match(/friday/i)
        name = 'Sa' if name.match(/saturday/i)

        program_title = campaign.Program_Title__c
        program_site = campaign.Program_Site__c

        cm.Section_Name_In_LMS__c = "#{campaign.Section_Name_Site_Prefix__c} #{current_user.first_name} (#{name})"
      end
      # Done

      cm.Apply_Button_Enabled__c = false
      cm.save
    else
      # Just warn me that this assertion failed so I can look into it...
      StaffNotifications.bug_report(current_user, "Campaign Member not set up.\nSelected timeslot: #{params[:selected_time]}\nCampaign: #{@enrollment.campaign_id}").deliver
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


    # Send a confirmation email too
    case current_user.applicant_type
      when 'undergrad_student'
        ConfirmationFlow.student_confirmed(current_user, program_title, program_site, params[:selected_time]).deliver
      when 'volunteer'
        ConfirmationFlow.coach_confirmed(current_user, program_title, program_site, params[:selected_time]).deliver
      else
        # intentionally blank, see above
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
    @user.bz_region = params[:user][:bz_region] if params[:user]
    if params[:applicant_type]
      @hide_other_applicant_types = true
    end
    # request.query_parameters is used instead of params because
    # we only want to hide if given in the URL. params would also
    # hide them on the event of validation failure which would be scary
    # if they came directly in
    if request.query_parameters[:user]
      @hide_other_universities = true if request.query_parameters[:user][:university_name]
      # The Bay Area link on signup needs to precheck... but also show the other regions
      # so the show_regions=true param allows us to achieve that - precheck without hiding.
      @hide_other_regions = true if request.query_parameters[:user][:bz_region] && !params[:show_regions]
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

    sf_lead_created = @new_user.create_on_salesforce
    if !sf_lead_created && @new_user.confirmed?
      # If we didn't create a new Lead, we need to mark the
      # existing record as confirmed here to sync up the data.
      @new_user.confirm_on_salesforce
    end

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
