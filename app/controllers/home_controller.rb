class HomeController < ApplicationController

  before_action :new_user, only: [:welcome, :volunteer, :apply, :partner, :please_wait]

  layout 'public'

  def index
    if current_user
      if current_user.is_administrator?
        redirect_to admin_root_path
      elsif current_user.in_lms?
        redirect_to "//#{Rails.application.secrets.canvas_server}/"
      else
        # Logged in user who may be applying or may be confirmed
        # let's check the enrollment and SF status
        enrollment = Enrollment.find_by_user_id(current_user.id)
        if current_user.program_attendance_confirmed
          # If already confirmed, the confirm path will have a nice next steps screen
          redirect_to user_confirm_path
        elsif enrollment
          sf = BeyondZ::Salesforce.new
          client = sf.get_client
          client.materialize('CampaignMember')
          cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(current_user.salesforce_id, enrollment.campaign_id)

          # If accepted, ask for confirmation, if not, go to welcome where
          # they will learn about how to continue their application
          if cm.Candidate_Status__c == "Accepted"
            redirect_to user_confirm_path
          else
            redirect_to welcome_path
          end
        else
          redirect_to welcome_path
        end
      end
    else
      # Otherwise, non-logged in users
      # just get the public home page
      # via the home/index view

      @wp_path = params[:wp_path] ? params[:wp_path] : '' # shortcut to the right page on the new site
      redirect_to "https://bebraven.org/#{@wp_path}"
    end
  end

  def please_wait

  end

  def welcome
    # just set here as a default so we can see it if it is improperly set below and
    # also to handle the fallback case for legacy users who applied before the salesforce system was in place
    @program_title = 'Braven'
    if user_signed_in?
      if current_user.program_attendance_confirmed
        redirect_to user_confirm_path
        return
      end
      existing_enrollment = Enrollment.find_by(:user_id => current_user.id)
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
      if cm && cm.Candidate_Status__c == "Accepted"
        redirect_to user_confirm_path
        return
      end

      if existing_enrollment.explicitly_submitted
        @application_received = true
        if existing_enrollment.campaign_id
          client.materialize('Campaign')
          campaign = SFDC_Models::Campaign.find(existing_enrollment.campaign_id)
          @program_title = campaign.Program_Title__c
        end
      else
        if existing_enrollment.campaign_id
          client.materialize('Campaign')
          campaign = SFDC_Models::Campaign.find(existing_enrollment.campaign_id)
          if campaign.Status == 'Completed'
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
