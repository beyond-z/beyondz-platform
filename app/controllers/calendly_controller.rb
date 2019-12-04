# The purpose of this controller is to handle notifications of calendly events.
# These events happen when volunteers signup for or cancel their interest in a volunteering opportunity
class CalendlyController < ApplicationController
  # this comes from cross site - calendly - and we have our own magic
  # token to use instead of the random normal CSRF check
  skip_before_filter :verify_authenticity_token, except: [:save_supplemental_details]

  layout 'public'

  def request_supplemental_details
    set_up_lists

    # if the invite already exists, update it, otherwise, create it...
    uuids_given = params[:event_type_uuid] && params[:invitee_uuid]
    if uuids_given
      @obj = CalendlyInvitee.by_event_type_and_invitee_uuids(params[:event_type_uuid], params[:invitee_uuid])
    end

    raise Exception.new("missing vital information on link") if @obj.nil?
    
    @obj.update!(params.permit(%i(
      assigned_to
      event_type_uuid
      event_type_name
      event_start_time
      event_end_time
      invitee_uuid
      invitee_first_name
      invitee_last_name
      invitee_email
      answer_1
      answer_2
      answer_3
      answer_4
      answer_5
      answer_6
      answer_7
      answer_8
      answer_9
      answer_10
      answer_11
      answer_12
      answer_13
      answer_14
      answer_15
    )))
  end

  def save_supplemental_details
    @obj = CalendlyInvitee.find(params[:id])
    ci = params[:calendly_invitee]
    @obj.update!(ci && ci.slice(:college_major, :industry, :job_function, :how_heard))

    # and update this on salesforce if it already exists
    # if it doesn't already exist, it will be created in the callback below
    # so we don't wanna do it here yet
    unless @obj.salesforce_contact_id.blank?
      contact = {}

      if contact['Industry__c'].blank?
        contact['Industry__c'] = @obj.industry
      else
        contact['Industry__c'] = "#{contact['Industry__c']}; #{@obj.industry}"
      end

      contact['Job_Function__c'] = @obj.job_function
      contact['Sourcing_Info__c'] = @obj.how_heard

      if contact['Fields_Of_Study__c'].blank?
        contact['Fields_Of_Study__c'] = @obj.college_major
      else
        contact['Fields_Of_Study__c'] = "#{contact['Fields_Of_Study__c']} #{@obj.college_major}"
      end

      salesforce = BeyondZ::Salesforce.new
      client = salesforce.get_client
      client.update('Contact', @obj.salesforce_contact_id, contact)
    end

  end

  # Called by calend.ly when a volunteer signs up for or cancels an event.
  # Note: you can expose your local dev environment server to the internet for calendly to call using ngrok
  # Go here: https://ngrok.com/ and download the installer.
  # Copy the script to /usr/local/bin/
  #
  # Now you can expose your local server to the internet
  # In this example, I'm exposing localhost:3001 using:
  # ngrok http 3001
  # That will launch a UI with the address to hit such as:
  # http://e866da42.ngrok.io -> localhost:3001
  #
  # Then I can setup the webhook with calend.ly:
  # curl --header "X-TOKEN: <your_token>" --data "url=http://e866da42.ngrok.io/calendly/invitee_action?magic_token=test&events[]=invitee.created&events[]=invitee.canceled" https://calendly.com/api/v1/hooks
  # Note: the token is available here: https://calendly.com/integrations
  # You can then delete that webhook using:
  # curl  -X DELETE --header "X-TOKEN: <your_token>" https://calendly.com/api/v1/hooks/<your_hook_id>

  # Sample data POSTed to this hook when something happens in calend.ly
  # is available here: http://developer.calendly.com/docs/sample-webhook-data
  #
  # This function creates or updates the Salesforce records based on the volunteer signup
  def invitee_action
    begin
      if check_magic_token

        event_type = params[:event]
        calendar_email = params[:payload][:event][:extended_assigned_to][0][:email] # This is the email of the account used to create the calendar
        email = params[:payload][:invitee][:email]
        first_name = params[:payload][:invitee][:first_name]
        last_name = params[:payload][:invitee][:last_name]
        event_name = params[:payload][:event_type][:name]
        start_time = params[:payload][:event][:invitee_start_time_pretty]

        event_type_uuid = params[:payload][:event_type][:uuid]
        invitee_uuid = params[:payload][:invitee][:uuid]

        obj = CalendlyInvitee.by_event_type_and_invitee_uuids(event_type_uuid, invitee_uuid)

        contact = {}
        contact['FirstName'] = first_name
        contact['LastName'] = last_name unless last_name.blank?
        contact['Email'] = email

        applicant_type = 'event_volunteer'
        selected_timeslot = "#{event_name}: #{start_time}"

        bz_region = User.get_bz_region(applicant_type, calendar_email)
        if bz_region.nil?
          raise NoRegionMappingException "No bz_region set b/c we haven't mapped the calendar #{calendar_email} to a region for #{applicant_type}"
        end

        if event_type == 'invitee.created'
          calendly_url = User.get_calendar_url(bz_region)
          phone = nil
          company = nil
          title_industry = nil
          city_state = nil
          career = nil
          params[:payload][:questions_and_answers].each do |qa|
            if qa[:question].downcase.include?('phone')
              phone = qa[:answer]
            elsif qa[:question].downcase.include?('employer')
              company = qa[:answer]
            elsif qa[:question].downcase.include?('title')
              title_industry = qa[:answer]
            elsif qa[:question].downcase.include?('career')
              career = qa[:answer]
            elsif qa[:question].downcase.include?('city, state')
              city_state = qa[:answer]
            end
          end

          # Note: city_state is supposed to be in the format: City, State.  E.g. Brooklyn, NY
          # If it's not, just set the city to the whole string
          city = city_state.split(',')[0]
          state = city_state.split(',')[1]

          # Create a BZ User in this platform
          current_user = User.find_by_email(email)
          if current_user.nil?
            current_user = User.new(:first_name => first_name, :last_name => last_name, :email => email, :phone => phone, :applicant_type => applicant_type, :city => city, :state => state, :external_referral_url => calendly_url, :bz_region => bz_region)
          else
            current_user.bz_region = bz_region
            current_user.applicant_type = applicant_type
          end
          current_user.skip_confirmation!
          current_user.save!

          # Create the user in salesforce
          contact['Phone'] = phone
          contact['Signup_Date__c'] = DateTime.now
          contact['MailingCity'] = city
          contact['MailingState'] = state unless state.nil?
          contact['Company__c'] = company
          contact['Title'] = title_industry # Both their title and industry could have commans, so can't split reliable.  Just stuff it all in Title field.
          contact['Career__c'] = career
          contact['BZ_Region__c'] = bz_region
          contact['User_Type__c'] = 'Event Volunteer'
          contact['BZ_User_Id__c'] = current_user.id
          contact['Came_From_to_Visit_Site__c'] = calendly_url

          contact['Job_Function__c'] = obj.job_function
          contact['Sourcing_Info__c'] = obj.how_heard

          if contact['Industry__c'].blank?
            contact['Industry__c'] = obj.industry
          else
            contact['Industry__c'] = "#{contact['Industry__c']}; #{obj.industry}"
          end

          if contact['Fields_Of_Study__c'].blank?
            contact['Fields_Of_Study__c'] = obj.college_major
          else
            contact['Fields_Of_Study__c'] = "#{contact['Fields_Of_Study__c']} #{obj.college_major}"
          end

          salesforce = BeyondZ::Salesforce.new
          existing_salesforce_id = salesforce.exists_in_salesforce(email)
          client = salesforce.get_client
          if !existing_salesforce_id.nil?
            client.update('Contact', existing_salesforce_id, contact)
          else
            # There is a bug in calendly where Last Name is not actually a required field.
            # This is meant to put something in that field so at least a Salesforce record is created.
            contact['LastName'] = '<Missing>' if last_name.blank?

            # Note: for new users that volunteer, we don't create BZ Users.  We just populate a new Salesforce
            # contact as though it was done manually.  Only Fellows and LCs get BZ Users after this calendly integration goes live.
            contact['LeadSource'] = 'Volunteer Signup'
            contact['OwnerId'] = current_user.salesforce_lead_owner_id # Note that if they are already in Salesforce, we assume they have an Owner already.
            contact = client.create('Contact', contact)
            existing_salesforce_id = contact.Id
          end

          current_user.salesforce_id = existing_salesforce_id
          current_user.skip_confirmation!
          current_user.save!

          cm = current_user.auto_add_to_salesforce_campaign('Confirmed', selected_timeslot)
          if cm.nil?
            logger.debug "######## Failed to create Campaign Member for #{current_user.inspect}.  Dunno why though."
          end


          obj.salesforce_contact_id = existing_salesforce_id
          obj.salesforce_campaign_member_id = cm["Id"]
          obj.save

          current_user.create_mailchimp

        elsif event_type == 'invitee.canceled'
          current_user = User.find_by_email(email)
          if !current_user.nil?
            current_user.bz_region = bz_region
            current_user.applicant_type = applicant_type
            cancellation_reason = params[:payload][:invitee][:cancel_reason]
            current_user.cancel_volunteer_signup(selected_timeslot, cancellation_reason)
          else
            logger.warn "No user with email = #{email} found -- NOOP"
          end

        else
          logger.warn "Unrecognized event type found: #{event_type} -- NOOP"
        end
      end
    # Need to catch all exceptions and always report that it was OK b/c Calendly will put the webhook
    # in a failed state and stop calling our endpoint until we delete and re-register the hook.
    rescue Exception => e
      logger.warn "###### Caught #{e.inspect} -- may have failed to add the Volunteer signup information into Salesforce."
    end

    render plain: 'OK'
  end

  # a simple filter to keep web crawlers from triggering this
  # needlessly
  def check_magic_token
    params[:magic_token] == Rails.application.secrets.calendly_magic_token
  end
end

class NoRegionMappingException < Exception
end
