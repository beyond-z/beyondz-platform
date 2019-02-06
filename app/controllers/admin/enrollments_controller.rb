require 'csv'
require 'lms'

class Admin::EnrollmentsController < Admin::ApplicationController
  def index
    @enrollments = Enrollment.all
    respond_to do |format|
      format.html { render }
    end
  end

  def show
    # We'll just reuse the form to display the data as a simple MVP,
    # punting this task back to the main enrollments controller which
    # knows how to do it
    redirect_to enrollment_path(params[:id])
  end

  def update
    if params[:enrollment][:student_id]
      @enrollment = Enrollment.find(params[:id])
      @enrollment.student_id = params[:enrollment][:student_id]
      @enrollment.save(validate: false)

      # also need to update this on Salesforce and on Canvas, for NLU
      if params[:id_type] == 'nlu'

        sf = BeyondZ::Salesforce.new
        client = sf.get_client
        client.materialize('CampaignMember')
        cm = SFDC_Models::CampaignMember.find_by_ContactId_and_CampaignId(@enrollment.user.salesforce_id, @enrollment.campaign_id)
        unless cm.nil?
          cm.Student_Id__c = @enrollment.student_id
          cm.save
        end

        lms = BeyondZ::LMS.new
        lms.update_nlu_login(@enrollment.user.canvas_user_id, "#{@enrollment.student_id.upcase}@nlu.edu")

      end
    end
    if params[:enrollment][:campaign_id]
      @enrollment = Enrollment.find(params[:id])
      @enrollment.campaign_id = params[:enrollment][:campaign_id]
      @enrollment.save(validate: false)
    end
    redirect_to admin_user_path(params[:enrollment][:user_id])
  end
end
