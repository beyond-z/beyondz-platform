class TasksController < ApplicationController

  before_action :require_student
  before_action :use_controller_js

  def show
    @coaches_comments = Comment.need_student_attention(current_user.id)
    @assignment = Assignment.find(params[:assignment_id])
    @task = Task.find(params[:id])
    @next_task = @task.next
    @previous_task = @task.previous
    @task.submit_previous_task!
  end


  def update
    @task = current_user.tasks.find_by_id(params[:id])
    @task.update(params[:task])
    @next_task = @task.next
    @previous_task = @task.previous

    respond_to do |format|
      format.html { render partial: 'tasks/action_box' }
      format.json { render json: { success: true } }
    end
  end

end
