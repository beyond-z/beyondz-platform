class AssignmentsController < ApplicationController

  def index
    uid = session[:user_id]
    if params[:student]
      uid = params[:student]
    end
    user = User.find(uid)

    if user.id != session[:user_id] && (user.coach == nil || user.coach.id != session[:user_id])
      raise Exception.new("Permission deined")
    end

    if params[:state] && (params[:state] == 'complete')
      @incomplete_assignments = user.assignments.incomplete.count > 0
      @complete_assignments = user.assignments.for_display.complete.reverse
      render 'completed'
    else
      @incomplete_assignments = user.assignments.for_display.incomplete
      @complete_assignments = user.assignments.complete.count > 0
    end

  end
  
end
