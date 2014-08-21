require 'csv'

class Admin::EnrollmentsController < Admin::ApplicationController
  def index
    @enrollments = Enrollment.all
    respond_to do |format|
      format.html { render }
      format.csv { render text: csv_export }
      format.xls { render text: @enrollments.to_xls }
    end
  end

  def show
    # We'll just reuse the form to display the data as a simple MVP,
    # punting this task back to the main enrollments controller which
    # knows how to do it
    redirect_to enrollment_path(params[:id])
  end

  private

  def csv_export
    CSV.generate do |csv|
      header = Array.new
      header << Enrollment.column_names
      csv << header
      @enrollments.each do |e|
        exportable = Array.new
        exportable << e.attributes.values_at(*Enrollment.column_names)
        csv << exportable
      end
    end
  end
end
