class TasksController < ApplicationController

  def index

    @tasks = Task.for_assignment(params[:assignment_id])

    @task = Task.new
  end

  def update
    ActiveRecord::Base.transaction do
      
      task = Task.find(params[:id])
      task.updated_at = Time.now

      # handle different task types
      if params[:task].has_key?(:user_confirm)
        task.state = (params[:task][:user_confirm] == 'true') ? "complete" : "new"
        
      elsif params[:task].has_key?(:files)
        if task.files.present?
          task.files.first.update_attribute(task.file_type => params[:task][:files][task.file_type.to_sym])
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
      format.html { redirect_to assignment_tasks_path(params[:assignment_id]) }
      format.json { render :json => {:success => true} }
    end
  end

end
