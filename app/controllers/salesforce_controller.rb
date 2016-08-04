require 'lms'

# The purpose of this controller is to centralize the endpoints for Salesforce triggers.
# Popup windows from SF buttons are still done in the admin area, but triggers notify
# this controller which will take appropriate action.
class SalesforceController < ApplicationController
  def sync_report_to_google_spreadsheet
    if check_magic_token
      sf = BeyondZ::Salesforce.new
      sf.delay.run_report_and_email_update(params[:report_id], params[:file_key], params[:worksheet_name], params[:email])
    end
    render plain: 'It will run in the background. Check your email in several minutes for a status update.'
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
      new_campaign = params[:newCampaignId]
      old_campaign = params[:oldCampaignId]
      cids.split(',').each do |cid|
        u = User.find_by_salesforce_id(cid)
        e = Enrollment.where(:user_id => u.id, :campaign_id => old_campaign)
        e.campaign_id = new_campaign
        e.save(validate: false)
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
      begin
        members.each do |member|
          user = User.find_by_salesforce_id(member.ContactId)
          next if user.nil?

          # I set up osqa first since it is a separate component
          # and may throw. I'd rather do it before attempting canvas
          # setup so we don't have half-created users in canvas if
          # this does happen to error out
          if Rails.application.secrets.qa_token && !Rails.application.secrets.qa_token.empty?
            setup_in_osqa(user)
          end

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
      # Gotta catch 'em all!
      # the point here is just to report the problem,
      # then the user will decide how to handle it later
      rescue Exception => e
        StaffNotifications.salesforce_sync_failed(e.to_s).deliver
      end
    end

    render plain: 'OK'
  end

  # a simple filter to keep web crawlers from triggering this
  # needlessly
  def check_magic_token
    params[:magic_token] == Rails.application.secrets.salesforce_magic_token
  end

  private

  def setup_in_osqa(user)
    if @qa_http.nil?
      @qa_http = Net::HTTP.new(Rails.application.secrets.qa_host, 443)
      @qa_http.use_ssl = true
      if Rails.application.secrets.canvas_allow_self_signed_ssl # reusing this config option since it is the same deal here
        @qa_http.verify_mode = OpenSSL::SSL::VERIFY_NONE # self-signed cert would fail
      end
    end

    request = Net::HTTP::Post.new('/account/create-user/')
    request.set_form_data(
      'access_token' => Rails.application.secrets.qa_token,
      'url' => "#{root_url}openid/user/#{user.id}",
      'name' => user.name,
      'email' => user.email
    )
    @qa_http.request(request)
  end
end
