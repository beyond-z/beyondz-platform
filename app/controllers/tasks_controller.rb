class TasksController < ApplicationController

  def index

    @tasks = Task.for_assignment(params[:assignment_id])

    @task = Task.new
  end

  def update
    task = Task.find(params[:id])
    task.updated_at = Time.now

    # handle different submission types
    if params[:task][:files]
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

    redirect_to assignment_tasks_path(params[:assignment_id])
  end

end
