class EnrollmentsController < ApplicationController
  before_filter :authenticate_user!
  before_action :setup_defaults

  # These defaults will show us what placeholders are supposed to
  # be there in the event that they don't load. It is not meant
  # to be seen by users - just to aid testing. If these appear in
  # an end user page, it is a bug.
  def setup_defaults
    @program_title = 'PROGRAM TITLE'
    @program_site = 'PROGRAM SITE'
    @request_availability = false
    @meeting_times = ''
    @sourcing_options = ''
    @student_id_required = false
  end

  layout 'public'

  # Some users like to write "N/A" on application fields when they
  # feel it is not applicable. Web conventions are to just leave the field
  # blank, and that's what the validator does. This helper function will
  # just replace variants of that written convention with the empty string
  # for storage and validation in the system.
  def handle_na(str)
    if str == 'na' || str == 'n/a' || str == 'N/a' || str == 'N/A'
      return ''
    end
    str
  end

  # On Salesforce URL fields, there is a 255 char max. We need a helper method
  # to keep those strings to the allowed size. Simply truncating is OK because
  # long URLs virtually always work when truncated anyway (the stuff at the end
  # tends to be search engine tracking spam)
  def limit_size(str, max)
    if str.length > max
      return str[0..max]
    end
    str
  end

  def new
    @enrollment = Enrollment.new
    @enrollment.user_id = current_user.id

    # We need to redirect them to edit their current application
    # if one exists. Otherwise, they can make a new one with some
    # prefilled data which we'll immediately send them to edit.
    existing_enrollment = nil
    if params[:campaign_id]
      existing_enrollment = Enrollment.find_by(:user_id => current_user.id, :campaign_id => params[:campaign_id])
    else
      # Default link is to just find any; we will start new from a campaign later
      existing_enrollment = Enrollment.find_by(:user_id => current_user.id)
    end
    if existing_enrollment.nil?
      # pre-fill from a previous enrollment, if possible
      old_enrollment = Enrollment.latest_for_user(current_user.id)
      if old_enrollment
        @enrollment = old_enrollment.dup
        @enrollment.explicitly_submitted = false
      else
        # otherwise, pre-fill any fields that are available from the user model
        @enrollment.first_name = current_user.first_name
        @enrollment.last_name = current_user.last_name
        @enrollment.email = current_user.email
        @enrollment.company = current_user.company
        @enrollment.undergrad_university = current_user.university_name
        @enrollment.phone = current_user.phone
        @enrollment.title = current_user.profession
        @enrollment.undergraduate_year = current_user.anticipated_graduation
        @enrollment.accepts_txt = true # to pre-check the box
      end

      if Rails.application.secrets.salesforce_username && current_user.salesforce_id
        # If Salesforce is enabled, we'll query it to see which campaign
        # this user is a member of and use that to fetch the associated
        # application out of our system.

        unless start_application_from_salesforce_campaign(params[:campaign_id])
          # If we can't start from a salesforce campaign, we don't
          # want them to actually start at all - w/o the campaign,
          # we can't save their info properly. This likely happens
          # because somebody used a direct link without actually
          # being added to the campaign.
          #
          # Send them back to the welcome path until they are
          # actually set up with an apply now button enabled.
          redirect_to welcome_path
          return
        end
      end

      # we know this is incomplete data, the user will be able
      # to save as they enter more so we don't validate until the end
      @enrollment.save(validate: false)

      # Sending them to the edit path ASAP means we can update the existing
      # row at any time as they input data, ensuring the AJAX thing doesn't
      # make duplicate rows and also won't lose rows
      redirect_to enrollment_path(@enrollment.id)
    else
      redirect_to enrollment_path(existing_enrollment.id)
    end
  end

  def start_application_from_salesforce_campaign(campaign_id = nil)
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')

    # We need to check all the campaign members to find the one that is most correct
    # for an application - one with an Application Type set up.
    query_result = client.http_get("/services/data/v#{client.version}/query?q=" \
      "SELECT Id, CampaignId FROM CampaignMember WHERE ContactId = '#{current_user.salesforce_id}' AND Campaign.IsActive = TRUE AND Campaign.Application_Type__c != ''")

    sf_answer = JSON.parse(query_result.body)

    cm_id = nil

    if campaign_id.nil?
      if sf_answer['records'].length != 1
        # If they aren't a member of one appropriate campaign,
        # they cannot start the application since we won't know
        # which one to show and their data is likely to be lost.
        return false
      end

      cm_id = sf_answer['records'][0]['Id']
    else
      # we need to start an application for a specific campaign... look through the members and find the right one
      sf_answer['records'].each do |record|
        if record['CampaignId'] == campaign_id
          cm_id = record['Id']
          break
        end
      end
    end

    if cm_id.nil?
      # Couldn't find the right campaign member, fail to start
      # so data isn't lost
      return false
    end

    cm = SFDC_Models::CampaignMember.find(cm_id)


    campaign = sf.load_cached_campaign(cm.CampaignId, client)

    # Set the data from the campaign so we can tie back to it
    @enrollment.campaign_id = campaign.Id
    @enrollment.position = campaign.Application_Type__c

    # And set on Salesforce that it has been started
    cm.Application_Status__c = 'started'
    cm.save

    true
  end

  def show
    # We'll show it by just displaying the pre-filled form
    # as that's the fastest thing that can possibly work for MVP
    @enrollment = Enrollment.find(params[:id])

    if @enrollment.user_id != current_user.id && !current_user.admin?
      redirect_to new_enrollment_path
      return
    end

    if @enrollment.explicitly_submitted
      # the user has hit the send button, so they finalized
      # their end. Since it may be in review already, we make
      # it read only unless the apply now is explicitly reenabled
      # (which is triggered through salesforce)

      sf = BeyondZ::Salesforce.new
      client = sf.get_client
      client.materialize('CampaignMember')
      cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(@enrollment.user.salesforce_id, @enrollment.campaign_id)

      unless cm.Apply_Button_Enabled__c
        @enrollment_read_only = true
      end
    end

    # We no longer allow easy changing from student to coach once
    # the initial selection is made. This allows us to separate the
    # forms better and tie them to salesforce campaigns.
    if @enrollment.position
      @position_is_set = true
    end

    if @enrollment.user_id == current_user.id
      # If the user is loading themselves and they have a newer one,
      # copy over the new fields into the blanks of this one, if applicable
      latest = Enrollment.latest_for_user(@enrollment.user_id)
      if latest.id != @enrollment.id
        Enrollment.attribute_names.each do |name|
          type = Enrollment.columns_hash[name].type
          if type == :string || type == :text
            if @enrollment[name].nil? || @enrollment[name] == ''
              @enrollment[name] = latest[name]
            end
          end
        end
      end
    end

    load_salesforce_campaign
    render 'new'
  end

  def load_salesforce_campaign
    if @enrollment.campaign_id
      sf = BeyondZ::Salesforce.new
      campaign = sf.load_cached_campaign(@enrollment.campaign_id)

      # It might be worth caching this at some point too.

      if campaign
        @program_title = campaign.Program_Title__c
        @program_site = campaign.Program_Site__c
        @request_availability = campaign.Request_Availability__c
        @meeting_times = campaign.Application_Type__c == 'volunteer' ? campaign.Volunteer_Opportunities__c : campaign.Meeting_Times__c
        @sourcing_options = campaign.Sourcing_Info_Options__c
        # Empty string instead of nil is easier to test for in the view
        # if this isn't filled in, we'll just skip the whole question
        # instead of displaying nonsense to the user.
        @sourcing_options = '' if @sourcing_options.nil?
        @student_id_required = campaign.Request_Student_Id__c
      end
    end
  end

  def update
    @enrollment = Enrollment.find(params[:id])
    @enrollment.update_attributes(enrollment_params)

    @enrollment.digital_footprint = limit_size(@enrollment.digital_footprint, 255)
    @enrollment.digital_footprint2 = limit_size(@enrollment.digital_footprint2, 255)

    @enrollment.meeting_times = '' # need to clear out because if none are checked, the next line never runs
    @enrollment.meeting_times = params[:meeting_times].join(';') if params[:meeting_times]

    if params[:enrollment][:gender_identity] != 'male' && params[:enrollment][:gender_identity] != 'female' && params[:other_gender_identity]
      @enrollment.gender_identity = params[:other_gender_identity]
    end

    if params[:meeting_times_required] && (@enrollment.meeting_times.nil? || @enrollment.meeting_times.empty?)
      @enrollment.check_meeting_times = true
    end

    # Lead sources is input as an array of checkboxes and details. This can be user-configured
    # easily later.
    #
    # Names with a colon in them expect details, so we remove excess semicolons there so the
    # resulting string is more human readable without extra punctuation.
    @enrollment.sourcing_info = ''
    @enrollment.sourcing_info = params[:sourcing_info].join(';') if params[:sourcing_info]

    # Always save without validating, this ensures the partial
    # data is not lost and allows resume upload to proceed even
    # if there are missing fields (which saves hassle for the user
    # having to re-upload it)
    @enrollment.save(validate: false)

    # Only validate on the explicit click of the submit button
    # because otherwise, they are probably just saving incomplete
    # data to finish later
    unless params[:user_submit].nil?
      @enrollment.sourcing_info = @enrollment.sourcing_info.gsub(':;', ': ').squeeze(';') if @enrollment.sourcing_info
      @enrollment.save(validate: true)
    end

    if @enrollment.errors.any?
      # errors will be displayed with the form btw
      load_salesforce_campaign

      @position_is_set = true if @enrollment.position

      render 'new'
      return
    else
      if params[:user_submit].nil?
        # the user didn't explicitly submit, update it and allow
        # them to continue editing
        # (this can happen if they do an intermediate save of work in progress)
        redirect_to enrollment_path(@enrollment.id)
      else
        # they did explicitly submit, finalize the application and show them the
        # modified welcome message so they know to wait for us to contact them

        @enrollment.explicitly_submitted = true
        @enrollment.save! # it should still validate successfully

        # Email the staff
        StaffNotifications.new_application(@enrollment).deliver

        # Update application status on Salesforce, if configured
        if Rails.application.secrets.salesforce_username
          enrollment_submitted_crm_actions
        end

        # Disable apply now early (Salesforce will do this too but it might take
        # a second and then the user would see the button again and might be
        # confused, so we do it locally too so they won't.)
        u = @enrollment.user
        u.apply_now_enabled = false
        u.save

        redirect_to welcome_path
      end
    end
  end

  def enrollment_submitted_crm_actions
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')
    cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(@enrollment.user.salesforce_id, @enrollment.campaign_id)
    if cm.nil?
      return
    end

    client.materialize('Contact')
    contact = SFDC_Models::Contact.find(@enrollment.user.salesforce_id)

    if contact
      # These need to be saved direct to contact because while
      # Salesforce claims to have them on CampaignMember, they are
      # actually pulled from the Contact and the API won't let us
      # access or update them through the CampaignMember.
      contact.Phone = @enrollment.phone
      contact.MailingCity = @enrollment.city
      contact.MailingState = @enrollment.state
      contact.Title = @enrollment.title
      contact.save
    end

    cm.Application_Status__c = 'Submitted'
    cm.Apply_Button_Enabled__c = false

    cm.Date_App_Submitted__c = DateTime.now

    cm.Industry__c = @enrollment.industry
    cm.Company__c = @enrollment.company
    cm.Middle_Name__c = @enrollment.middle_name
    cm.Accepts_Text__c = @enrollment.accepts_txt

    cm.Cannot_Attend__c = @enrollment.cannot_attend

    cm.Student_Id__c = @enrollment.student_id

    cm.Eligible__c = @enrollment.will_be_student
    cm.GPA_Circumstances__c = @enrollment.gpa_circumstances
    cm.Other_Commitments__c = @enrollment.other_commitments

    cm.Grad_Degree__c = @enrollment.grad_degree

    cm.Birthdate__c = @enrollment.birthdate

    cm.Post_Grad__c = @enrollment.post_graduation_plans
    cm.Why_BZ__c = @enrollment.why_bz
    cm.Passions_Expertise__c = @enrollment.passions_expertise
    cm.Meaningful_Activity__c = @enrollment.meaningful_activity
    cm.Relevant_Experience__c = @enrollment.relevant_experience

    cm.Undergrad_University__c = @enrollment.undergrad_university
    cm.Undergraduate_Year__c = @enrollment.undergraduate_year
    cm.Anticipated_Graduation_Semester__c = @enrollment.anticipated_graduation_semester
    cm.Major__c = @enrollment.major
    cm.GPA__c = @enrollment.gpa

    cm.Enrollment_Year__c = @enrollment.enrollment_year
    cm.Enrollment_Semester__c = @enrollment.enrollment_semester

    cm.Previous_University__c = @enrollment.previous_university

    cm.Conquered_Challenge__c = @enrollment.conquered_challenge
    cm.Languages__c = @enrollment.languages
    cm.Sourcing_Info__c = @enrollment.sourcing_info
    cm.Available_Meeting_Times__c = @enrollment.meeting_times
    cm.Additional_Comments__c = @enrollment.comments

    cm.Grad_University__c = @enrollment.grad_school
    cm.Graduate_Year__c = @enrollment.anticipated_grad_school_graduation

    cm.Digital_Footprint__c = limit_size(@enrollment.digital_footprint, 255)
    cm.Digital_Footprint_2__c = limit_size(@enrollment.digital_footprint2, 255)

    cm.Resume__c = @enrollment.resume.url if @enrollment.resume.present?

    cm.Reference_1_Name__c = @enrollment.reference_name
    cm.Reference_1_How_Known__c = @enrollment.reference_how_known
    cm.Reference_1_How_Long_Known__c = @enrollment.reference_how_long_known
    cm.Reference_1_Email__c = handle_na(@enrollment.reference_email)
    cm.Reference_1_Phone__c = handle_na(@enrollment.reference_phone)

    cm.Reference_2_Name__c = @enrollment.reference2_name
    cm.Reference_2_How_Known__c = @enrollment.reference2_how_known
    cm.Reference_2_How_Long_Known__c = @enrollment.reference2_how_long_known
    cm.Reference_2_Email__c = handle_na(@enrollment.reference2_email)
    cm.Reference_2_Phone__c = handle_na(@enrollment.reference2_phone)

    cm.African_American__c = @enrollment.bkg_african_americanblack
    cm.Asian_American__c = @enrollment.bkg_asian_american
    cm.Latino__c = @enrollment.bkg_latino_or_hispanic
    cm.Native_Alaskan__c = @enrollment.bkg_native_alaskan
    cm.Native_American__c = @enrollment.bkg_native_american_american_indian
    cm.Native_Hawaiian__c = @enrollment.bkg_native_hawaiian
    cm.Pacific_Islander__c = @enrollment.bkg_pacific_islander
    cm.White__c = @enrollment.bkg_whitecaucasian
    cm.Multi_Ethnic__c = @enrollment.bkg_multi_ethnicmulti_racial
    cm.Identify_As_Person_Of_Color__c = @enrollment.identify_poc
    cm.Identify_As_Low_Income__c = @enrollment.identify_low_income
    cm.Identify_As_First_Gen__c = @enrollment.identify_first_gen
    cm.Other_Race__c = @enrollment.bkg_other
    cm.Hometown__c = @enrollment.hometown
    cm.Pell_Grant_Recipient__c = @enrollment.pell_grant
    cm.Study_Abroad__c = @enrollment.study_abroad
    cm.Gender_Identity__c = @enrollment.gender_identity

    cm.save
  end

  def create
    @enrollment = Enrollment.create(enrollment_params)

    if @enrollment.errors.any?
      render 'new'
      return
    else
      flash[:message] = 'Your application has been saved'
      redirect_to enrollment_path(@enrollment.id)
    end
  end

  def enrollment_params
    # allow all like 60 fields without listing them all
    params.require(:enrollment).permit!
  end
end
