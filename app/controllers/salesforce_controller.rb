require 'lms'

# The purpose of this controller is to centralize the endpoints for Salesforce triggers.
# Popup windows from SF buttons are still done in the admin area, but triggers notify
# this controller which will take appropriate action.
class SalesforceController < ApplicationController
  def sync_report_to_google_spreadsheet 
    if check_magic_token 
      sf = BeyondZ::Salesforce.new 
      sf.delay.run_report(params[:report_id], params[:file_key], params[:worksheet_name]) 
    end 
    render plain: 'OK' 
  end 

  def change_apply_now
    if check_magic_token
      params[:yes_list].split(',').each do |id|
        u = User.find_by_salesforce_id(id)
        if u
          u.apply_now_enabled = true
          u.save!
        end
      end
      params[:no_list].split(',').each do |id|
        u = User.find_by_salesforce_id(id)
        if u
          u.apply_now_enabled = false
          u.save!
        end
      end
    end

    render plain: 'OK'
  end

  def record_converted_leads
    if check_magic_token
      params[:changes].split(',').each do |change|
        parts = change.split(':')
        u = User.find_by_salesforce_id(parts[0])
        if u
          u.salesforce_id = parts[1]
          u.save!

          u.auto_add_to_salesforce_campaign
        end
      end
    end

    render plain: 'OK'
  end

  def change_campaigns
    if check_magic_token
      cids = params[:contactIds]
      new_campaign = params[:campaignId]
      reset = params[:reset] == 'true'
      cids.split(',').each do |cid|
        u = User.find_by_salesforce_id(cid)
        if u
          existing_enrollment = Enrollment.find_by(:user_id => u.id)
          if existing_enrollment
            existing_enrollment.campaign_id = new_campaign
            if reset
              # We want to allow them to update and re-submit the app
              # so we will unsubmit but keep their data in place.
              existing_enrollment.explicitly_submitted = false
            end
            # It may be in-progress, so we don't want to validate it
            # at this time, just update the one piece of inf.
            existing_enrollment.save(validate: false)
            # Note: this assumes the old and new campaigns are both the same
            # type, for example, student or LC. If they want to change tracks
            # entirely, we will need to  have them start an all-new application.
          end

          if reset
            # This should reset the user so they can basically start fresh
            # Above, we unsubmitted the app. Here, we want to unconfirm too
            u.program_attendance_confirmed = false

            # We also want to disconnect them from Canvas so they can reapply. When we
            # resync, it will find their existing account and reconnect them at that time.
            u.canvas_user_id = nil

            u.save
            # Note that other variables are changed on the Salesforce side
            # which can update us through triggers too
          end
        end
      end
    end

    render plain: 'OK'
  end


  def sync_to_lms
    if check_magic_token
      sf = BeyondZ::Salesforce.new
      client = sf.get_client
      client.materialize('Campaign')
      client.materialize('CampaignMember')
      campaign = SFDC_Models::Campaign.find(params[:campaignId])

      lms = BeyondZ::LMS.new

      # If you change the condition on this query, also update
      # BZ_SyncToLMS.apxc so the list on Salesforce keeps in sync.
      members = client.query("
        SELECT
          ContactId, Section_Name_In_LMS__c
        FROM
          CampaignMember
        WHERE
          CampaignId = '#{campaign.Id}'
        AND
          Candidate_Status__c = 'Confirmed'
        AND
          Section_Name_In_LMS__c <> NULL
        AND
          Section_Name_In_LMS__c <> ''
      ")
      members.each do |member|
        user = User.find_by_salesforce_id(member.ContactId)
        next if user.nil?
        lms.sync_user_logins(user)
        type = 'STUDENT'
        if campaign.Type == 'Leadership Coaches'
          type = 'TA'
        end
        lms.sync_user_course_enrollment(
          user,
          campaign.Target_Course_ID_In_LMS__c[0].to_i,
          type,
          member.Section_Name_In_LMS__c
        )

        if campaign.Coach_Course_ID__c && campaign.Coach_Course_ID__c[0]
          lms.sync_user_course_enrollment(
            user,
            campaign.Coach_Course_ID__c[0].to_i,
            'STUDENT',
            campaign.Section_Name_in_LMS_Coach_Course__c
          )
        end


        user.save!
      end
    end

    render plain: 'OK'
  end

  # a simple filter to keep web crawlers from triggering this
  # needlessly
  def check_magic_token
    params[:magic_token] == Rails.application.secrets.salesforce_magic_token
  end
end
