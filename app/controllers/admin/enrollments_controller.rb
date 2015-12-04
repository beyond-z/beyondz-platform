require 'csv'

class Admin::EnrollmentsController < Admin::ApplicationController
  def index
    @enrollments = Enrollment.all
    respond_to do |format|
      format.html { render }
      format.csv { render text: csv_export }
      format.xls { send_data(@enrollments.to_xls) }
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

  private

  def csv_export
    CSV.generate do |csv|
      header = *Enrollment.column_names
      header << 'Uploaded Resume'
      csv << header
      @enrollments.each do |e|
        exportable = e.attributes.values_at(*Enrollment.column_names)
        if e.resume.present?
          exportable << e.resume.url
        else
          exportable << '<none uploaded>'
        end
        csv << exportable
      end
    end
  end
end
