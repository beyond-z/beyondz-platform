class HomeController < ApplicationController

  layout 'public'

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
      redirect_to enrollments_path
    end
    @assignment_definitions = AssignmentDefinition.all
  end

  def welcome
    unless user_signed_in?
      redirect_to new_user_session_path
    end
  end
end
