class HomeController < ApplicationController
  before_action :new_user, only: [:welcome, :volunteer, :apply, :partner, :please_wait]

  layout 'public'

  def index
    if current_user
      if current_user.is_administrator?
        redirect_to admin_root_path
      elsif current_user.in_lms?
        # If LMS, go to canvas here as well as /welcome just because
        # this is such a frequent and simple case that duplicating the line
        # here gives the end user a small optimization that I feel is worth it.
        redirect_to "//#{Rails.application.secrets.canvas_server}/"
      else
        # All other users go to welcome where the complex logic
        # of where to go for what type of user lives (no longer duplicated here)
        redirect_to welcome_path
      end
    else
      # Otherwise, non-logged in users
      # just get the join page
      redirect_to new_user_path
    end
  end

  def please_wait
  end

  # This will be used for more accurate redirection - the JS will
  # poll this to only redirect once it is done (instead of just using
  # a fixed timer), and tell them where to go afterward - we can send
  # the user directly to the application if they are ready for it.
  def please_wait_status
    obj = {}

    if current_user.applicant_type == 'volunteer' || current_user.applicant_type == 'undergrad_student' || current_user.applicant_type == 'temp_volunteer'
      obj['ready'] = current_user.apply_now_enabled
      obj['path'] = new_enrollment_path
    else
      obj['ready'] = true
      obj['path'] = welcome_path
    end

    render :json => obj
  end

  def welcome
    @apply_now_showing = false
    # just set here as a default so we can see it if it is improperly set below and
    # also to handle the fallback case for legacy users who applied before the salesforce system was in place
    @program_title = 'Braven'
    if user_signed_in?
      if current_user.in_lms?
        redirect_to "//#{Rails.application.secrets.canvas_server}/"
        return
      end
      if current_user.program_attendance_confirmed
        redirect_to user_confirm_path
        return
      end
      existing_enrollment = Enrollment.latest_for_user(current_user.id)
      return if existing_enrollment.nil?

      sf = BeyondZ::Salesforce.new
      client = sf.get_client
      client.materialize('CampaignMember')
      cm = nil
      if current_user.salesforce_id && existing_enrollment.campaign_id
        cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(current_user.salesforce_id, existing_enrollment.campaign_id)
      end

      # If accepted, we go back to confirmation (see above in the index method)
      # repeated here in welcome so if they bookmarked this, they won't get lost
      if cm && cm.Candidate_Status__c == 'Accepted'
        # only confirm if the Campaign requires it

        campaign = sf.load_cached_campaign(existing_enrollment.campaign_id, client)
        if campaign && campaign.Request_Availability__c == true && campaign.Request_Student_Id__c == false
          redirect_to user_confirm_path
          return
        end
      end

      if existing_enrollment.explicitly_submitted
        @application_received = true
        if existing_enrollment.campaign_id
          campaign = sf.load_cached_campaign(existing_enrollment.campaign_id, client)
          @program_title = campaign.Program_Title__c
        end
      else
        if existing_enrollment.campaign_id
          campaign = sf.load_cached_campaign(existing_enrollment.campaign_id, client)
          if campaign && campaign.Status == 'Completed'
            @program_completed = true
          end
        end

      end
    end
  end

  def volunteer
  end

  def apply
  end

  def supporter_info
  end

  def partner
  end

  def jobs
  end

  private

  def new_user
    if user_signed_in?
      @new_user = current_user
    elsif params[:new_user_id]
      @new_user = User.find(params[:new_user_id])
    end
  end
end
