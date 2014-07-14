class EnrollmentsController < ApplicationController

  layout 'public'

  def new
    get_states
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

    if @new_user.errors.any?
      get_states
      @user = @new_user
      render 'new'
      return
    end

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

  private

  def get_states
    @states = [
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO',
      'CT', 'DE', 'DC', 'FL', 'GA', 'HI',
      'ID', 'IL', 'IN', 'IA', 'KS', 'KY',
      'LA', 'ME', 'MD', 'MA', 'MI', 'MN',
      'MS', 'MO', 'MT', 'NE', 'NV', 'NH',
      'NJ', 'NM', 'NY', 'NC', 'ND', 'OH',
      'OK', 'OR', 'PA', 'RI', 'SC', 'SD',
      'TN', 'TX', 'UT', 'VT', 'VA', 'WA',
      'WV', 'WI', 'WY'
    ]
  end
end
