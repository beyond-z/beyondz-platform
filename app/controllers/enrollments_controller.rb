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
    @new_user = User.create(user)

    redirect_path = case @new_user.applicant_type
    when 'student'
      student_info_path(new_user_id: @new_user.id)
    when 'college_faculty' || 'professional'
      coach_info_path(new_user_id: @new_user.id)
    when 'supporter'
      supporter_info_path(new_user_id: @new_user.id)
    else
      others_info_path(new_user_id: @new_user.id)
    end

    redirect_to redirect_path
  end
end
