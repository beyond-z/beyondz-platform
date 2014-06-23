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
      :keep_updated,
      :anticipated_graduation)
    if user[:applicant_type] == 'other'
      user[:applicant_type] = params[:other_type]
    end
    @new_user = User.create!(user)

    redirect_to redirect_to_welcome_path(@new_user)
  end
end
