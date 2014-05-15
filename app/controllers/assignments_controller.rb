class AssignmentsController < ApplicationController
  before_action :require_student

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

      @coaches_comments = Comment.need_student_attention(uid)
    end
  end

  def show
    @coaches_comments = Comment.need_student_attention(current_user.id)
    @assignment = Assignment.find(params[:id])
    # When we show the assignment, we want it to immediately
    # show the user what needs their attention:
    # the first unfinished task for this assignment.
    if current_user.is_coach?
      tasks = @assignment.tasks.need_coach_attention
    else
      tasks = @assignment.tasks.need_student_attention
    end

    if tasks.any?
      @task = tasks.first
      @next_task = @task.next
      @previous_task = @task.previous
    else
      @task = nil
      @next_task = nil
      @previous_task = nil
    end
  end

  def update
    assignment = Assignment.find(params[:id])

    if params[:start] && (params[:start] == 'true')
      assignment.start!
      redirect_to assignment_path(assignment)
      return
    elsif params[:submit] && (params[:submit] == 'true')
      assignment.submit!
    elsif params[:approve] && (params[:approve] == 'true')
      if assignment.user.coach == current_user
        assignment.approve!
        redirect_to coaches_path
        return
      end
    end

    redirect_to assignments_path
  end
end
