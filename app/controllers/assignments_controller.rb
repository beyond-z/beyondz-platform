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
    assignment = Assignment.find(params[:id])

    @assignment = assignment

    @coaches_comments = Comment.needs_student_attention(current_user.id, assignment.id)

    if params[:task_id]
      @task = Task.find(params[:task_id])
    else
      tasks = assignment.tasks.needs_student_attention
      @task = tasks.first
    end

    tasks = assignment.tasks.order(:id)
    @next_task = nil
    @previous_task = nil
    last = nil
    next_is_it = false
    tasks.each do |task|
      if next_is_it
        @next_task = task
        next_is_it = false
        break
      end
      if task == @task
        @previous_task = last
        next_is_it = true
      end
      last = task
    end
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
