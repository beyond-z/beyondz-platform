# The purpose of this controller is to handle notifications of calendly events.
# These events happen when volunteers signup for or cancel their interest in a volunteering opportunity
class CalendlyController < ApplicationController
  # this comes from cross site - calendly - and we have our own magic
  # token to use instead of the random normal CSRF check
  skip_before_filter :verify_authenticity_token

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
    if check_magic_token

      eventType = params[:event]
      calendar_email = params[:payload][:event][:extended_assigned_to][0][:email] # This is the email of the account used to create the calendar
      email = params[:payload][:invitee][:email]
      first_name = params[:payload][:invitee][:first_name]
      last_name = params[:payload][:invitee][:last_name]
      event_name = params[:payload][:event_type][:name]
      start_time = params[:payload][:event][:invitee_start_time_pretty]

      contact = {}
      contact['FirstName'] = first_name
      contact['LastName'] = last_name
      contact['Email'] = email

      applicant_type = 'temp_volunteer'
      selected_timeslot = "#{event_name}: #{start_time}"

      bz_region = User.get_bz_region(applicant_type, calendar_email)
      if (bz_region == nil)
        raise NoRegionMappingException "No bz_region set b/c we haven't mapped the calendar #{calendar_email} to a region for #{applicant_type}"
      end

      if (eventType == "invitee.created")
        calendly_url = User.get_calendar_url(bz_region)
        phone = nil
        city = nil
        state = nil
        sourcing_info = nil
        params[:payload][:questions_and_answers].each do |qa|
          if (qa[:question] == 'Phone')
            phone = qa[:answer]
          elsif (qa[:question] == 'City that you live in?')
            city = qa[:answer]
          elsif (qa[:question] == 'State that you live in?')
            state = qa[:answer]
          elsif (qa[:question] == 'How did you hear about us?')
            sourcing_info = qa[:answer]
          end
        end

        # Create a BZ User in this platform
        current_user = User.find_by_email(email)
        if (current_user == nil)
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
        contact['MailingState'] = state
        contact['Sourcing_Info__c'] = sourcing_info
        contact['BZ_Region__c'] = bz_region
        contact['User_Type__c'] = 'Temp Volunteer'
        contact['BZ_User_Id__c'] = current_user.id
        contact['Came_From_to_Visit_Site__c'] = calendly_url

        salesforce = BeyondZ::Salesforce.new
        existing_salesforce_id = salesforce.exists_in_salesforce(email)
        client = salesforce.get_client
        if (existing_salesforce_id != nil)
          client.update('Contact', existing_salesforce_id, contact)
        else
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

        cm = current_user.auto_add_to_salesforce_campaign('Confirmed', selected_timeslot, sourcing_info)
        if (cm == nil)
          logger.debug "######## Failed to create Campaign Member for #{current_user.inspect}.  Dunno why though."
        end

      elsif (eventType == "invitee.canceled")
        current_user = User.find_by_email(email)
        if (current_user != nil)
          current_user.bz_region = bz_region
          current_user.applicant_type = applicant_type
          cancellation_reason = params[:payload][:invitee][:cancel_reason]
          current_user.cancel_volunteer_signup(selected_timeslot, cancellation_reason)
        else
          logger.warn "No user with email = #{email} found -- NOOP"
        end

      else
        logger.warn "Unrecognized event type found: #{eventType} -- NOOP";
      end

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
