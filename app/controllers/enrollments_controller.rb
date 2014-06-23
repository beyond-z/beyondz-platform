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

    redirect_path = general_info_path(new_user_id: @new_user.id)

    case @new_user.applicant_type
    when 'student'
      redirect_path = student_info_path(new_user_id: @new_user.id)
    when 'college_faculty' || 'professional'
      redirect_path = coach_info_path(new_user_id: @new_user.id)
    when 'supporter'
      redirect_path = supporter_info_path(new_user_id: @new_user.id)
    end

    redirect_to redirect_path
  end
end
