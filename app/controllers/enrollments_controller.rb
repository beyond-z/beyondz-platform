class EnrollmentsController < ApplicationController

  before_action :use_controller_js

  layout 'public'

  def new
    @enrollment = Enrollment.new
  end

  def create

    @enrollment = Enrollment.create(enrollment_params)

    if @enrollment.errors.any?
      render 'new'
      return
    else
      redirect_to root_path
    end
  end

  def enrollment_params
    params[:enrollment].permit(:user_id)
  end

end