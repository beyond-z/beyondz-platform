class HomeController < ApplicationController
  def index
    if current_user
      if current_user.is_administrator?
        redirect_to "/admin/"
      elsif current_user.is_coach?
        redirect_to coaches_path
      else
        redirect_to assignments_path
      end
    end
    @assignment_definitions = AssignmentDefinition.all
  end
end
