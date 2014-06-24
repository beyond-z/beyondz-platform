class ConfirmationsController < Devise::ConfirmationsController

  private

  def after_confirmation_path_for(resource_name, resource)
    sign_in(resource_name, resource)

    # This is currently very similar to the code in the enrollments_controller
    # for dispatching. It isn't the same though: here, we aren't dealing with a
    # new user so we do NOT want it to display the "check your email" instructions.
    #
    # We may also want to point it to a whole new page before long.
    redirect_path = general_info_path

    case current_user.applicant_type
    when 'student'
      redirect_path = student_info_path
    when 'college_faculty' || 'professional'
      redirect_path = coach_info_path
    when 'supporter'
      redirect_path = supporter_info_path
    end

    redirect_path
  end

end
