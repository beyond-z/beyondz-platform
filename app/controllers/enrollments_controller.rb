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

    if user[:applicant_type] == 'other'
      user[:applicant_details] = params[:other_details]
    end
    if user[:applicant_type] == 'professional'
      user[:applicant_details] = params[:professional_details]
    end

    # Each of these has different names in the form to ensure no data
    # conflict as the user explores the bullets, but they all map to
    # the same database field since it is really the same data
    if user[:applicant_type] == 'grad_student'
      user[:anticipated_graduation] = params[:anticipated_grad_graduation]
    end
    if user[:applicant_type] == 'undergrad_student'
      user[:anticipated_graduation] = params[:anticipated_undergrad_graduation]
    end
    if user[:applicant_type] == 'school_student'
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
