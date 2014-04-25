class AssignmentsController < ApplicationController

  def index
    user = User.find(session[:user_id])

    if params[:state] && (params[:state] == 'complete')
      @incomplete_assignments = user.assignments.incomplete.count
      @complete_assignments = user.assignments.for_display.complete.reverse
      render 'completed'
    else
      @incomplete_assignments = user.assignments.for_display.incomplete
      @complete_assignments = user.assignments.complete.count
    end
  end

end
