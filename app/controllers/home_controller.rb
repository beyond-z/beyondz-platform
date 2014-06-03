class HomeController < ApplicationController
  def index
    if current_user
      if current_user.is_administrator?
        redirect_to admin_root_path
      elsif current_user.coach?
        redirect_to coach_root_path
      else
        redirect_to assignments_path
      end
    else
      redirect_to users_login_path
    end
    @assignment_definitions = AssignmentDefinition.all
  end
end
