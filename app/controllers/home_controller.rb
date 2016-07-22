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


      sf = BeyondZ::Salesforce.new
      client = sf.get_client
      client.materialize('CampaignMember')

      @applications = []

      # We need to check all the campaign members to find the one that is most correct
      # for an application - one with an Application Type set up.
      query_result = client.http_get("/services/data/v#{client.version}/query?q=" \
        "SELECT
          Id, CampaignId, Candidate_Status__c, Apply_Button_Enabled__c
        FROM CampaignMember WHERE ContactId = '#{current_user.salesforce_id}' AND Campaign.IsActive = TRUE AND Campaign.Application_Type__c != ''")

      sf_answer = JSON.parse(query_result.body)

      sf_answer['records'].each do |record|
        campaign = sf.load_cached_campaign(record['CampaignId'])
        campaign_type =
        case campaign.Type
        when 'Program Participants'
          'Fellow'
        when 'Leadership Coaches'
          'Coaching'
        else
          'Volunteer'
        end

        apply_text = (campaign_type == 'Volunteer') ? 'Registration' : 'Application'

        word = 'Start'
        path = new_enrollment_path(:campaign_id => record['CampaignId'])
        accepted = false
        started = false
        submitted = false
        program_completed = false
        program_title = campaign.Program_Title__c
        apply_now_enabled = record['Apply_Button_Enabled__c']

        key_application_path = ''
        @key_application_count = 0


        enrollments = Enrollment.where(:user_id => @new_user.id, :campaign_id => record['CampaignId'])
        if enrollments.any?
          enrollment = enrollments.first
          word = 'Continue'
          started = true
          accepted = record['Candidate_Status__c'] == 'Accepted'

          # It is recent if it was updated today.... for use in not showing old informational messages
          recent = enrollment.updated_at.to_date == Date.today

          path = ''
          will_show_message = false
          submitted = enrollment.explicitly_submitted
          program_completed = campaign.Status == 'Completed'

          unless submitted
            # If they application isn't submitted, the logical place for them
            # to go is to the application so they can finish it
            path = enrollment_path(enrollment)
          end

          if accepted && campaign.Request_Availability__c == true && campaign.Request_Student_Id__c == false
            # If accepted, we go back to confirmation (see above in the index method)
            # repeated here in welcome so if they bookmarked this, they won't get lost
            # just only done if the confirmation is actually required!
            path = user_confirm_path
          end
        end

        if program_completed
          # If the program is completed, always keep them here - it will display a message for them
          path = ''
          will_show_message = true
        end

        if submitted && !apply_now_enabled && recent
          # it will show a message for recently submitted applications
          will_show_message = true
        end

        @applications << { :word => word, :started => started, :path => path, :campaign_type => campaign_type, :accepted => accepted, :application_received => submitted, :program_completed => program_completed, :program_title => program_title, :apply_now_enabled => apply_now_enabled, :apply_text => apply_text, :recent => recent }

        if path != ''
          key_application_path = path
          @key_application_count += 1
        elsif will_show_message
          # We might not be going anywhere, but will show a message,
          # so consider this application as a visible key destination
          # for the user
          @key_application_count += 1
        end
      end

      if @key_application_count == 1 && key_application_path != ''
        # If they only have one valid destination, just go ahead and send them right there immediately
        redirect_to key_application_path
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
