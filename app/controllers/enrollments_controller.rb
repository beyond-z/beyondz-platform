class EnrollmentsController < ApplicationController

  layout 'public'

  def new
    @user = User.new
  end

  def create
    user = params[:user].permit(
      :first_name,
      :last_name,
      :email,
      :password,
      :applicant_type,
      :keep_updated)

    case user[:applicant_type]
    when 'other'
      user[:applicant_details] = params[:other_details]
    when 'professional'
      user[:applicant_details] = params[:professional_details]
    when 'grad_student'
      # Each of these has different names in the form to ensure no data
      # conflict as the user explores the bullets, but they all map to
      # the same database field since it is really the same data
      user[:anticipated_graduation] = params[:anticipated_grad_graduation]
    when 'undergrad_student'
      user[:anticipated_graduation] = params[:anticipated_undergrad_graduation]
    when 'school_student'
      user[:anticipated_graduation] = 'Grade ' + params[:grade]
    end

    @new_user = User.create(user)

    unless @new_user.id
      # If User.create failed; we have an existing user
      # trying to sign up again. Instead, let's tell them
      # to log in
      flash[:message] = 'You have already joined us, please log in.'
      redirect_to new_user_session_path
      return
    end

    redirect_to redirect_to_welcome_path(@new_user)
  end
end
