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
    cm = SFDC_Models::CampaignMember.find_by_ContactId(current_user.salesforce_id)
    unless cm.nil?
      application = Application.find_by_associated_campaign(cm.CampaignId)
      unless application.nil?
        @enrollment.position = application.form
      end
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
      # it read only.

      @enrollment_read_only = true
    end

    # We no longer allow easy changing from student to coach once
    # the initial selection is made. This allows us to separate the
    # forms better and tie them to salesforce campaigns.
    if @enrollment.position
      @position_is_set = true
    end

    render 'new'
  end

  def update
    @enrollment = Enrollment.find(params[:id])
    @enrollment.update_attributes(enrollment_params)

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

  def enrollment_submitted_crm_actions
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')
    cm = SFDC_Models::CampaignMember.find_by_ContactId(@enrollment.user.salesforce_id)
    if cm
      cm.Application_Status__c = 'Submitted'
      cm.Apply_Button_Enabled__c = false
      cm.save
    end

    client.materialize('Contact')

    contact = SFDC_Models::Contact.find(@enrollment.user.salesforce_id)

    if contact
      client.materialize('Task')
      task = SFDC_Models::Task.new
      task.Status = 'Not Started'
      task.Subject = 'Review the application'
      task.WhoId = contact.Id
      task.OwnerId = contact.OwnerId
      task.IsReminderSet = false
      task.Description = 'Review the application or assign it to someone else to handle'
      task.save
    end
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
