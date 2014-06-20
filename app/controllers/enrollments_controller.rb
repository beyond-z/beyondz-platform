class EnrollmentsController < ApplicationController

  layout 'public'

  def index

  end

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
      :keep_updated,
      :anticipated_graduation)
    if user[:applicant_type] == 'other'
      user[:applicant_type] = params[:other_type]
    end
    @new_user = User.create(user)
    # sign_in(:user, @new_user)
  end

  def welcome
    if !user_signed_in?
      redirect_to new_user_session_path
    end

  end

end
