class TasksController < ApplicationController

  before_action :require_student
  before_action :use_controller_js

  def show
    @coaches_comments = Comment.need_student_attention(current_user.id)
    @assignment = Assignment.find(params[:assignment_id])
    @task = Task.find(params[:id])
    @next_task = @task.next
    @previous_task = @task.previous
  end


  def update
    @task = current_user.tasks.find_by_id(params[:id])
    @next_task = @task.next
    @previous_task = @task.previous

    if @task.update(params[:task])
      # succeeded, continue
      if @task.last?
        redirect_to assignments_path
      else
        redirect_to assignment_task_path(@next_task.assignment, @next_task)
      end
    else
      # failed, return to form
      redirect_to assignment_task_path(@task.assignment, @task)

      ## Not ajaxing this request right now... may come back to this
      # respond_to do |format|
      #   format.html { render partial: 'tasks/action_box' }
      #   format.json { render json: { success: true } }
      # end
    end
  end

end
