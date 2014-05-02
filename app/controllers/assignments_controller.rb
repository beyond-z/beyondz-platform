class AssignmentsController < ApplicationController

  before_action :require_login

  private

  def require_login
    unless @user_logged_in
      flash[:error] = "Please log in to see your assignments."
      redirect_to "/users/login?redirect_to=/assignments"
    end
  end

  public

  def index
    uid = session[:user_id]
    if params[:student]
      uid = params[:student]
    end
    user = User.find(uid)

    if user.id != session[:user_id] && (user.coach == nil || user.coach.id != session[:user_id])
      raise ApplicationHelper::PermissionDenied
    end

    if params[:state] && (params[:state] == 'complete')
      @incomplete_assignments = user.assignments.not_submitted.count
      @complete_assignments = user.assignments.for_display.submitted.reverse
      render 'completed'
    else
      @incomplete_assignments = user.assignments.for_display.not_submitted
      @complete_assignments = user.assignments.submitted.count

      @coaches_comments = Comment.for_student_attention(uid)
    end
  end

  def update
    assignment = Assignment.find(params[:id])

    if params[:start] && (params[:start] == 'true')
      assignment.start!
    elsif params[:submit] && (params[:submit] == 'true')
      assignment.submit!
    end

    redirect_to assignments_path
  end
end
