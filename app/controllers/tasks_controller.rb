class TasksController < ApplicationController

  def index
    @tasks = Task.for_assignment(params[:assignment_id])
    @task = Task.new
  end

  def show
    @coaches_comments = Comment.need_student_attention(current_user.id)
    @assignment = Assignment.find(params[:assignment_id])
    @task = Task.find(params[:id])
    @next_task = @task.next
    @previous_task = @task.previous

    @previous_task_url = @previous_task ? assignment_task_path(@previous_task.assignment, @previous_task) : nil
    @next_task_url = @next_task ? assignment_task_path(@next_task.assignment, @next_task) : nil
  end


  def update
    ActiveRecord::Base.transaction do

      task = Task.find(params[:id])
      task.updated_at = Time.now

      raise ApplicationHelper::PermissionDenied if task.user_id != current_user.id

      # handle different task types
      if params[:task].key?(:user_confirm)
        if params[:task][:user_confirm] == 'true'
          task.submit!
        end

      elsif params[:task].key?(:files)
        if task.files.present?
          task_file_params = params[:task][:files][task.file_type.to_sym]
          # restrict to single/first file for now
          task.files.first.update_attribute(task.file_type, task_file_params)
        else
          task.files << TaskFile.create(
            task_definition_id: task.task_definition.id,
            task_id: task.id,
            task.file_type => params[:task][:files][task.file_type.to_sym]
          )
        end
      end
      task.save!

    end

    respond_to do |format|
      format.html { redirect_to :back } # assignment_tasks_path(params[:assignment_id]) }
      format.json { render json: { success: true } }
    end
  end

end
