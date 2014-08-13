class EnrollmentsController < ApplicationController

  before_filter :authenticate_user!
  before_action :use_controller_js

  layout 'public'

  def new
    @enrollment = Enrollment.new

    # pre-fill fields that are available from the user
    @enrollment.first_name = current_user.first_name
    @enrollment.last_name = current_user.last_name
    @enrollment.email = current_user.email
  end

  def show
    # We'll show it by just displaying the pre-filled form
    # as that's the fastest thing that can possibly work for MVP
    @enrollment = Enrollment.find(params[:id])
    render 'new'

    # FIXME: permission check
  end

  def update
    @enrollment = Enrollment.find(params[:id])
    @enrollment.update_attributes(enrollment_params)
    @enrollment.save!

    redirect_to enrollment_path(@enrollment.id)
  end

  def create

    @enrollment = Enrollment.create(enrollment_params)

    if @enrollment.errors.any?
      render 'new'
      return
    else
      redirect_to enrollment_path(@enrollment.id)
    end
  end

  def enrollment_params
    # allow all like 60 fields without listing them all
    params.require(:enrollment).permit!
  end

end
