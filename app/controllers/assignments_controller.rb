class AssignmentsController < ApplicationController

  before_action :require_student
  before_action :use_controller_js

  def index
    uid = current_user.id
    if params[:student]
      uid = params[:student]
    end
    user = User.find(uid)

    if user.id != current_user.id && (user.coach.nil? || user.coach.id != current_user.id)
      raise ApplicationHelper::PermissionDenied
    end

    if params[:state] && (params[:state] == 'complete')
      @incomplete_assignments = user.assignments.need_student_attention.count
      @complete_assignments = user.assignments.for_display\
        .do_not_need_student_attention.reverse
      render 'completed'
    else
      @incomplete_assignments = user.assignments.for_display\
        .need_student_attention
      @complete_assignments = user.assignments.do_not_need_student_attention\
        .count

      @coaches_comments = Comment.need_student_attention(uid)
    end
  end

  def show
    @coaches_comments = Comment.need_student_attention(current_user.id)
    @assignment = Assignment.find(params[:id])

    tasks = @assignment.tasks.need_student_attention
    unless tasks.any?
      tasks = @assignment.tasks
    end

    @task = tasks.first
    @next_task = @task.next
    @previous_task = @task.previous
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
