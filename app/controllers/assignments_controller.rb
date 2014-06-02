class AssignmentsController < ApplicationController

  before_action :require_student
  before_action :use_controller_js

  def index
    uid = session[:user_id]
    if params[:student]
      uid = params[:student]
    end
    user = User.find(uid)

    if user.id != session[:user_id] && (user.coach.nil? || user.coach.id != session[:user_id])
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
    if current_user.coach?
      tasks = @assignment.tasks.need_coach_attention
    else
      tasks = @assignment.tasks.need_student_attention
    end

    if tasks.any?
      @task = tasks.first
      @next_task = @task.next
      @previous_task = @task.previous

      @previous_task_url = @previous_task ? assignment_task_path(@previous_task.assignment, @previous_task) : nil
      @next_task_url = @next_task ? assignment_task_path(@next_task.assignment, @next_task) : nil
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
    end

    redirect_to assignments_path
  end
end
