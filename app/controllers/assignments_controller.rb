class AssignmentsController < ApplicationController
  before_action :require_login

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

      @coaches_comments = Comment.needs_student_attention(uid)
    end
  end

  def show
    @coaches_comments = Comment.needs_student_attention(current_user.id)
    assignment = Assignment.find(params[:id])

    @assignment = assignment
    # When we show the assignment, we want it to immediately
    # show the user what needs their attention:
    # the first unfinished task for this assignment.
    tasks = assignment.tasks.needs_student_attention
    @task = tasks.first
    @next_task = @task.next
    @previous_task = @task.previous
  end

  def update
    assignment = Assignment.find(params[:id])

    if params[:start] && (params[:start] == 'true')
      assignment.start!
      redirect_to "/assignments/#{assignment.id}"
      return
    elsif params[:submit] && (params[:submit] == 'true')
      assignment.submit!
    end

    redirect_to assignments_path
  end
end
