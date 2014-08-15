class EnrollmentsController < ApplicationController

  before_filter :authenticate_user!
  before_action :use_controller_js

  layout 'public'

  def new
    @enrollment = Enrollment.new

    # We need to redirect them to edit their current application
    # if one exists. Otherwise, they can make a new one.
    existing_enrollment = Enrollment.find_by(:user_id => current_user.id)
    if !existing_enrollment.nil?
      redirect_to enrollment_path(existing_enrollment.id)
    end

    # pre-fill any fields that are available from the user model
    @enrollment.first_name = current_user.first_name
    @enrollment.last_name = current_user.last_name
    @enrollment.email = current_user.email
  end

  def show
    # We'll show it by just displaying the pre-filled form
    # as that's the fastest thing that can possibly work for MVP
    @enrollment = Enrollment.find(params[:id])

    if @enrollment.user_id != current_user.id && !current_user.admin?
      redirect_to new_enrollment_path
    end

    render 'new'
  end

  def update
    @enrollment = Enrollment.find(params[:id])
    @enrollment.update_attributes(enrollment_params)
    @enrollment.save!

    flash[:message] = 'Your application has been updated'
    redirect_to enrollment_path(@enrollment.id)
  end

  def create

    @enrollment = Enrollment.create(enrollment_params)

    if @enrollment.errors.any?
      render 'new'
      return
    else
      flash[:message] = 'Your application has been saved'
      redirect_to enrollment_path(@enrollment.id)
    end
  end

  def enrollment_params
    # allow all like 60 fields without listing them all
    params.require(:enrollment).permit!
  end

end
