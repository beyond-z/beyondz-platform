class MentorController < ApplicationController

  layout 'public'

  before_filter :authenticate_user!, :only => [:mentee_app, :mentor_app, :save_mentee_app, :save_mentor_app]

  def new

  end

  def load_existing_data
    @first_name = current_user.first_name
    @last_name = current_user.last_name
    @email = current_user.email
    @phone = current_user.phone
  end

  def format_date(date)
    if date.instance_of? String
      date_object = Date.parse(date)
    else
      date_object = date
    end

    begin
      date_object.strftime("%B %-d, %Y")
    rescue
      date
    end
  end

  # On Salesforce URL fields, there is a 255 char max. We need a helper method
  # to keep those strings to the allowed size. Simply truncating is OK because
  # long URLs virtually always work when truncated anyway (the stuff at the end
  # tends to be search engine tracking spam)
  def limit_size(str, max)
    if str.length > max
      return str[0...max]
    end
    str
  end

  def load_campaign_data(type)

    set_up_lists

    #@program_title = 'Professional Mentor Program'
    #@program_site = 'Test Braven Site'
    #@contact_email = 'admin@bebraven.org'
    #@program_area = "#{@program_site} Area" # FIXME
    #@number_of_weeks = 4 # FIXME
    #@kickoff_location = @program_site # FIXME
    #@due_date = "December 25, 2018" # FIXME
    #@kickoff_date = "January 1, 2019" # FIXME
    #@end_date = "February 1, 2019" # FIXME
    #@desired_industries = "LIST INDUSTRIES\nto test" #FIXME
    #return true

    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')

    # We need to check all the campaign members to find the one that is most correct
    # for an application - one with an Application Type set up.
    query_result = client.http_get("/services/data/v#{client.version}/query?q=" \
      "SELECT Id, CampaignId FROM CampaignMember WHERE ContactId = '#{current_user.salesforce_id}' AND Campaign.IsActive = TRUE AND Campaign.Type = '#{type}'")

    sf_answer = JSON.parse(query_result.body)

    cm_id = nil

    if sf_answer['records'].length != 1
      # If they aren't a member of one appropriate campaign,
      # they cannot start the application since we won't know
      # which one to show and their data is likely to be lost.
      Rails.logger.info("#{sf_answer['records'].length} records for #{current_user.salesforce_id} <#{current_user.email}> for active campaigns of #{type}")
      return false
    end

    cm_id = sf_answer['records'][0]['Id']

    cm = SFDC_Models::CampaignMember.find(cm_id)

    campaign = sf.load_cached_campaign(cm.CampaignId, client)

    @campaign_id = campaign.Id

    @program_title = campaign.Program_Title__c
    @program_site = campaign.Program_Site__c
    @contact_email = campaign.Contact_Email__c.blank? ? sf.load_cached_user_email(campaign.OwnerId) : campaign.Contact_Email__c
    @program_area = campaign.PM_Area__c
    @number_of_weeks = campaign.PM_Number_Weeks__c.to_i
    @kickoff_location = campaign.PM_Kickoff_Location__c
    @due_date = format_date(campaign.PM_Application_Due_Date__c)
    @kickoff_date = format_date(campaign.PM_Kickoff_Date__c)
    @end_date = format_date(campaign.PM_End_Date__c)
    @desired_industries = campaign.PM_Industries_List__c
    @sourcing_options = campaign.Sourcing_Info_Options__c
    @sourcing_options = '' if @sourcing_options.nil?


    return true
  end

  def university_update
    current_user.university_name = params[:university_name]
    current_user.save
    redirect_to mentee_app_path
  end

  def region_update
    current_user.bz_region = params[:bz_region]
    current_user.save
    redirect_to mentor_app_path
  end

  def mentor_app
    load_existing_data

    if current_user.bz_region.blank?
      render 'pick_region'
      return
    end

    # is the user in the campaign? if no, add them now
    #if false
    begin
      if current_user.salesforce_id.blank?
        # skip ahead to contact as we are adding to campaign below
        current_user.create_on_salesforce(true)
      end
      iv = {}
      iv["Application_Status__c"] = "Started"
      current_user.ensure_in_salesforce_campaign_for(current_user.bz_region, nil, "professional_mentor", iv)
    rescue Exception => e
      Rails.logger.error(e)
      render 'inactive_campaign'
      return
    end
    #end

    if !load_campaign_data("Mentor")
      render 'inactive_campaign'
      return
    end

  end

  def mentee_app
    load_existing_data

    if current_user.university_name.blank?
      render 'pick_university'
      return
    end

    # is the user in the campaign? if no, add them now
    # if false
    begin
      if current_user.salesforce_id.blank?
        # skip ahead to contact as we are adding to campaign below
        current_user.create_on_salesforce(true)
      end

      iv = {}
      iv["Application_Status__c"] = "Started"
      current_user.ensure_in_salesforce_campaign_for(nil, current_user.university_name, "mentee", iv)
    rescue Exception => e
      Rails.logger.error(e)
      render 'inactive_campaign'
      return
    end
    # end

    if !load_campaign_data("Mentee")
      render 'inactive_campaign'
      return
    end
  end

  def save_mentor_app
    # This is hacky, but we create the application with some prepopulated fields on the new user form. Start from that.
    # Things like functional_area are already set on it.
    application = MentorApplication.where("user_id = #{current_user.id}").first
    unless application
      application = MentorApplication.new(:user_id => current_user.id, :employer => current_user.company, :phone => current_user.phone, :title => current_user.profession)
      Rails.logger.warn "MentorApplication not found for #{current_user}. It was supposed to be created on the profile page. Creating a blank one. Probably means this was an existing user."
    end

    application.application_type = 'mentor'
    application.campaign_id = params[:campaign_id]

    application.first_name = params[:first_name]
    application.last_name = params[:last_name]
    application.email = params[:email]
    application.phone = params[:phone]
    application.linkedin_url = params[:linkedin_url]
    application.city = params[:city]
    application.state = params[:state]
    application.work_city = params[:work_city]
    application.work_state = params[:work_state]
    application.major = params[:major]
    if params[:major] == 'other'
      application.major = params[:major_other]
    end
    application.other_industries = params[:other_industries]
    application.comfortable = params[:comfortable].nil? ? "" : params[:comfortable].join(", ")
    application.can_commit = params[:can_commit]
    application.can_meet = params[:can_meet]
    application.why_want_to_be_pm = params[:why_want_to_be_pm]
    application.what_skills = params[:what_skills]
    application.what_do = params[:what_do]
    application.how_hear = limit_size(params[:sourcing_info].join(';'), 200) if params[:sourcing_info]
    application.how_hear = application.how_hear.gsub(':;', ': ').squeeze(';') if application.how_hear
    application.reference_name = params[:reference_name]
    application.reference_email = params[:reference_email]
    application.reference_phone = params[:reference_phone]
    application.reference2_name = params[:reference2_name]
    application.reference2_email = params[:reference2_email]
    application.reference2_phone = params[:reference2_phone]

    application.bkg_african_americanblack = params[:bkg_african_americanblack]
    application.bkg_asian_american = params[:bkg_asian_american]
    application.bkg_latino_or_hispanic = params[:bkg_latino_or_hispanic]
    application.bkg_native_alaskan = params[:bkg_native_alaskan]
    application.bkg_native_american_american_indian = params[:bkg_native_american_american_indian]
    application.bkg_native_hawaiian = params[:bkg_native_hawaiian]
    application.bkg_pacific_islander = params[:bkg_pacific_islander]
    application.bkg_whitecaucasian = params[:bkg_whitecaucasian]
    application.bkg_multi_ethnicmulti_racial = params[:bkg_multi_ethnicmulti_racial]
    application.identify_poc = params[:identify_poc]
    application.identify_low_income = params[:identify_low_income]
    application.identify_first_gen = params[:identify_first_gen]
    application.bkg_other = params[:bkg_other]
    application.pell_grant = params[:pell_grant]
    application.gender_identity = params[:gender_identity] == "other" ? params[:other_gender_identity] : params[:gender_identity]
    application.lingering_questions = params[:lingering_questions]
    application.what_gain = params[:what_gain].nil? ? "" : params[:what_gain].join("; ")

    application.save!

    save_to_salesforce(application)
  end

  def save_mentee_app
    application = MentorApplication.new

    application.user_id = current_user.id

    application.application_type = 'mentee'
    application.campaign_id = params[:campaign_id]

    application.first_name = params[:first_name]
    application.last_name = params[:last_name]
    application.email = params[:email]
    application.phone = params[:phone]
    application.linkedin_url = params[:linkedin_url]
    application.when_graduate = params[:when_graduate]
    if application.when_graduate == 'other'
      application.when_graduate = params[:when_graduate_other]
    end
    application.city = params[:city]
    application.state = params[:state]
    application.major = params[:major]
    if params[:major] == 'other'
      application.major = params[:major_other]
    end
    application.interests = params[:interests].nil? ? "" : params[:interests].join("; ")
    application.desired_job = params[:desired_job]
    application.why_interested_in_field = params[:why_interested_in_field]
    application.strengths_and_growths = params[:strengths_and_growths]
    application.what_most_helpful = params[:what_most_helpful]
    application.willing_to_work_with_other_field = params[:willing_to_work_with_other_field]
    application.can_commit = params[:can_commit]
    application.why_interested_in_pm = params[:why_interested_in_pm]
    application.what_do = params[:what_do]
    application.how_hear = params[:how_hear]
    application.lingering_questions = params[:lingering_questions]
    application.interests_areas = params[:interests_areas].nil? ? "" : params[:interests_areas].join("; ")
    application.internships_count =  params[:internships_count]

    
    application.save

    save_to_salesforce(application)
  end

  # for storage, we want to strip out anything non-numeric
  def format_phone_for_storage(phone)
    return phone if phone.blank?
    phone.gsub(/[^0-9]/, '')
  end

  def save_to_salesforce(application)

    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('CampaignMember')
    cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(User.find(application.user_id).salesforce_id, application.campaign_id)
    if cm.nil?
      return
    end

    client.materialize('Contact')
    contact = SFDC_Models::Contact.find(User.find(application.user_id).salesforce_id)

    if contact
      # These need to be saved direct to contact because while
      # Salesforce claims to have them on CampaignMember, they are
      # actually pulled from the Contact and the API won't let us
      # access or update them through the CampaignMember.
      contact.Phone = format_phone_for_storage(application.phone)
      contact.Email = application.email
      contact.MailingCity = application.city
      contact.MailingState = application.state
      contact.FirstName = application.first_name
      contact.LastName = application.last_name
      contact.Title = application.title
      begin
        # it is ok for this to fail, most likely reason would be email changed to a duplicate.
        # (which is handled externally to this code)
        # let's just log it and see what's going on in practice.
        contact.save
      rescue Exception => e
        Rails.logger.error(e)
      end
    end

    cm.Application_Status__c = 'Submitted'
    cm.Apply_Button_Enabled__c = false

    cm.Date_App_Submitted__c = DateTime.now

    cm.Can_Commit_to_Mentoring__c = application.can_commit
    cm.Can_Meet_Mentee__c = application.can_meet == "yes"
    cm.Comfortable_Mentoring_Skills__c = application.comfortable
    cm.Desired_Job__c = application.desired_job
    cm.Company__c = application.employer
    cm.Employer_Industry__c = application.employer_industry
    cm.How_Heard_About_Opportunity__c = application.how_hear
    cm.Sourcing_Info__c = application.how_hear
    cm.Industry__c = application.industry
    cm.Career_Field_Interests__c = application.interests
    cm.Digital_Footprint__c = application.linkedin_url
    cm.Major__c = application.major
    cm.Other_Industries_Experience__c = application.other_industries
    cm.Reference_2_Email__c = application.reference2_email
    cm.Reference_2_Name__c = application.reference2_name
    cm.Reference_2_Phone__c = application.reference2_phone
    cm.Reference_1_Email__c = application.reference_email
    cm.Reference_1_Name__c = application.reference_name
    cm.Reference_1_Phone__c = application.reference_phone
    cm.Strengths_And_Growths__c = application.strengths_and_growths
    cm.What_Would_Do_If__c = application.what_do
    cm.What_Most_Helpful_Job_Search__c = application.what_most_helpful
    cm.Relevant_Experience__c = application.what_skills
    cm.Anticipated_Graduation__c = application.when_graduate
    cm.Why_Interested_In_PM__c = application.why_interested_in_pm
    cm.Why_Interested_In_Field__c = application.why_interested_in_field
    cm.Why_Want_To_Be_PM__c = application.why_want_to_be_pm
    cm.Willing_To_Work_With_Other_Field__c = application.willing_to_work_with_other_field == "yes"
    cm.Work_City__c = application.work_city
    cm.Work_State__c = application.work_state

    cm.African_American__c = application.bkg_african_americanblack.blank? ? false : true
    cm.Asian_American__c = application.bkg_asian_american.blank? ? false : true
    cm.Latino__c = application.bkg_latino_or_hispanic.blank? ? false : true
    cm.Native_Alaskan__c = application.bkg_native_alaskan.blank? ? false : true
    cm.Native_American__c = application.bkg_native_american_american_indian.blank? ? false : true
    cm.Native_Hawaiian__c = application.bkg_native_hawaiian.blank? ? false : true
    cm.Pacific_Islander__c = application.bkg_pacific_islander.blank? ? false : true
    cm.White__c = application.bkg_whitecaucasian.blank? ? false : true
    cm.Multi_Ethnic__c = application.bkg_multi_ethnicmulti_racial.blank? ? false : true
    cm.Identify_As_Person_Of_Color__c = application.identify_poc.blank? ? false : true
    cm.Identify_As_Low_Income__c = application.identify_low_income.blank? ? false : true
    cm.Identify_As_First_Gen__c = application.identify_first_gen.blank? ? false : true
    cm.Other_Race__c = application.bkg_other
    cm.Hometown__c = application.hometown
    cm.Pell_Grant_Recipient__c = application.pell_grant.blank? ? false : true
    cm.Gender_Identity__c = application.gender_identity

    cm.Additional_Comments__c = application.lingering_questions

    cm.What_Gain_By_PM__c = application.what_gain
    cm.Functional_Area__c = application.functional_area
    cm.Functional_Areas_Interested__c = application.interests_areas
    cm.Internships_Count__c = application.internships_count


    cm.save

  end
end
