require 'csv'

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
    if params[:enrollment][:campaign_id]
      @enrollment = Enrollment.find(params[:id])
      @enrollment.campaign_id = params[:enrollment][:campaign_id]
      @enrollment.save(validate: false)
    end
    redirect_to admin_user_path(params[:enrollment][:user_id])
  end
end
