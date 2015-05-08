class HomeController < ApplicationController

  before_action :new_user, only: [:welcome, :volunteer, :apply, :partner, :please_wait]

  layout 'public'

  def index
    if current_user
      if current_user.is_administrator?
        redirect_to admin_root_path
      elsif current_user.in_lms?
        redirect_to "//#{Rails.application.secrets.canvas_server}/"
      elsif current_user.coach?
        redirect_to coaches_root_path
      elsif current_user.student?
        redirect_to assignments_path
      else
        # This is a logged in user who is not yet
        # accepted into the program - we'll give them
        # the welcome screen so they can learn more.
        redirect_to welcome_path
      end
    end
    # Otherwise, non-logged in users
    # just get the public home page
    # via the home/index view
  end

  def please_wait

  end

  def welcome
    # just set here as a default so we can see it if it is improperly set below and
    # also to handle the fallback case for legacy users who applied before the salesforce system was in place
    @program_title = 'Beyond Z'
    if user_signed_in?
      if current_user.program_attendance_confirmed
        redirect_to user_confirm_path
      end
      existing_enrollment = Enrollment.find_by(:user_id => current_user.id)
      return if existing_enrollment.nil?

      if existing_enrollment.explicitly_submitted
        @application_received = true
        if existing_enrollment.campaign_id
          sf = BeyondZ::Salesforce.new
          client = sf.get_client
          client.materialize('Campaign')
          campaign = SFDC_Models::Campaign.find(existing_enrollment.campaign_id)
          @program_title = campaign.Program_Title__c
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
