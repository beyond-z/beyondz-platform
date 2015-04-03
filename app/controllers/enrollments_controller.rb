class EnrollmentsController < ApplicationController

  before_filter :authenticate_user!

  layout 'public'

  def new
    @enrollment = Enrollment.new
    @enrollment.user_id = current_user.id

    # We need to redirect them to edit their current application
    # if one exists. Otherwise, they can make a new one with some
    # prefilled data which we'll immediately send them to edit.
    existing_enrollment = Enrollment.find_by(:user_id => current_user.id)
    if existing_enrollment.nil?
      # pre-fill any fields that are available from the user model
      @enrollment.first_name = current_user.first_name
      @enrollment.last_name = current_user.last_name
      @enrollment.email = current_user.email
      @enrollment.university = current_user.university_name
      @enrollment.anticipated_graduation = current_user.anticipated_graduation
      @enrollment.accepts_txt = true # to pre-check the box

      if Rails.application.secrets.salesforce_username && current_user.salesforce_id
        # If Salesforce is enabled, we'll query it to see which campaign
        # this user is a member of and use that to fetch the associated
        # application out of our system.

        set_application_from_salesforce_campaign
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

  def set_application_from_salesforce_campaign
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')
    client.materialize('Campaign')
    cm = SFDC_Models::CampaignMember.find_by_ContactId(current_user.salesforce_id)
    unless cm.nil?
      campaign = SFDC_Models::Campaign.find(cm.CampaignId)

      @enrollment.campaign_id = campaign.Id
      @enrollment.position = campaign.Application_Type__c
    end
  end

  def show
    # We'll show it by just displaying the pre-filled form
    # as that's the fastest thing that can possibly work for MVP
    @enrollment = Enrollment.find(params[:id])

    if @enrollment.user_id != current_user.id && !current_user.admin?
      redirect_to new_enrollment_path
    end

    if @enrollment.explicitly_submitted
      # the user has hit the send button, so they finalized
      # their end. Since it may be in review already, we make
      # it read only unless the apply now is explicitly reenabled
      # (which is triggered through salesforce)

      unless @enrollment.user.apply_now_enabled
        @enrollment_read_only = true
      end
    end

    # We no longer allow easy changing from student to coach once
    # the initial selection is made. This allows us to separate the
    # forms better and tie them to salesforce campaigns.
    if @enrollment.position
      @position_is_set = true
    end


    if @enrollment.campaign_id
      sf = BeyondZ::Salesforce.new
      client = sf.get_client
      client.materialize('Campaign')
      campaign = SFDC_Models::Campaign.find(@enrollment.campaign_id)

      # It might be worth caching this at some point too.

      if campaign
        @program_title = campaign.Program_Title__c
        @program_site = campaign.Program_Site__c
        @request_availability = campaign.Request_Availability__c
        @meeting_times = campaign.Meeting_Times__c
      end
    end

    render 'new'
  end

  def update
    @enrollment = Enrollment.find(params[:id])
    @enrollment.update_attributes(enrollment_params)

    @enrollment.meeting_times = params[:meeting_times].join(';') if params[:meeting_times]
    @enrollment.lead_sources = params[:lead_sources].join(';') if params[:lead_sources]

    # Always save without validating, this ensures the partial
    # data is not lost and allows resume upload to proceed even
    # if there are missing fields (which saves hassle for the user
    # having to re-upload it)
    @enrollment.save(validate: false)

    # Only validate on the explicit click of the submit button
    # because otherwise, they are probably just saving incomplete
    # data to finish later
    unless params[:user_submit].nil?
      @enrollment.save(validate: true)
    end

    if @enrollment.errors.any?
      # errors will be displayed with the form btw
      render 'new'
      return
    else
      if params[:user_submit].nil?
        # the user didn't explicitly submit, update it and allow
        # them to continue editing
        # (this can happen if they do an intermediate save of work in progress)
        flash[:message] = 'Your application has been updated'
        redirect_to enrollment_path(@enrollment.id)
      else
        # they did explicitly submit, finalize the application and show them the
        # modified welcome message so they know to wait for us to contact them

        @enrollment.explicitly_submitted = true
        @enrollment.save! # it should still validate successfully

        # Email Abby
        StaffNotifications.new_application(@enrollment).deliver

        # Update application status on Salesforce, if configured
        if Rails.application.secrets.salesforce_username
          enrollment_submitted_crm_actions
        end

        redirect_to welcome_path
      end
    end
  end

  # Since this method is long but not complex (it is just a list of field mapping)
  # it is expedient to disable the rubocop thing here instead of trying to appease
  # it by making a simple thing complex.
  #
  # rubocop:disable MethodLength
  def enrollment_submitted_crm_actions
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')
    cm = SFDC_Models::CampaignMember.find_by_ContactId(@enrollment.user.salesforce_id)

    client.materialize('Contact')
    contact = SFDC_Models::Contact.find(@enrollment.user.salesforce_id)

    if contact
      # These need to be saved direct to contact because while
      # Salesforce claims to have them on CampaignMember, they are
      # actually pulled from the Contact and the API won't let us
      # access or update them through the CampaignMember.
      cm.Phone = @enrollment.phone
      cm.City = @enrollment.city
      cm.State = @enrollment.state
      contact.save!
    end

    if cm
      cm.Application_Status__c = 'Submitted'
      cm.Apply_Button_Enabled__c = false

      cm.Middle_Name__c = @enrollment.middle_name
      cm.Accepts_Text__c = @enrollment.accepts_txt

      cm.Eligible__c = @enrollment.will_be_student
      cm.GPA_Circumstances__c = @enrollment.gpa_circumstances
      cm.Other_Commitments__c = @enrollment.current_volunteer_activities

      cm.Grad_Degree__c = @enrollment.grad_degree

      cm.Birthdate__c = @enrollment.birthdate

      cm.Summer__c = @enrollment.last_summer
      cm.Post_Grad__c = @enrollment.post_graduation_plans
      cm.Why_BZ__c = @enrollment.why_bz
      cm.Community_Connection__c = @enrollment.community_connection
      cm.Passions_Expertise__c = @enrollment.personal_passion
      cm.Meaningful_Activity__c = @enrollment.meaningful_experience
      cm.Relevant_Experience__c = @enrollment.teaching_experience

      cm.Undergrad_University__c = @enrollment.university
      cm.Undergraduate_Year__c = @enrollment.anticipated_graduation
      cm.Major__c = @enrollment.major
      cm.GPA__c = @enrollment.gpa
      cm.Grad_University__c = @enrollment.grad_school
      cm.Graduate_Year__c = @enrollment.anticipated_grad_school_graduation

      if @enrollment.position == 'student'
        cm.Digital_Footprint__c = @enrollment.online_resume
        cm.Digital_Footprint_2__c = @enrollment.online_resume2
      else
        if @enrollment.twitter_handle && @enrollment.twitter_handle != ''
          cm.Digital_Footprint__c = "https://twitter.com/#{@enrollment.twitter_handle}"
        end
        cm.Digital_Footprint_2__c = @enrollment.personal_website
      end

      cm.Resume__c = @enrollment.resume.url if @enrollment.resume.present?

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

      cm.save
    end

    make_salesforce_task(client, contact) if contact
  end
  # rubocop: enable Metrics/MethodLength

  def make_salesforce_task(client, contact)
    client.materialize('Task')
    task = SFDC_Models::Task.new
    task.Status = 'Not Started'
    task.Subject = "Review the application for #{@enrollment.user.name}"
    task.WhoId = contact.Id
    task.OwnerId = contact.OwnerId
    task.WhatId = @enrollment.campaign_id
    task.ActivityDate = Date.today
    task.IsReminderSet = true
    task.Priority = 'Normal'
    task.Description = "Review the application for #{@enrollment.user.name} " \
      'and change their Application Status or assign it to someone else to handle'
    task.save
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
