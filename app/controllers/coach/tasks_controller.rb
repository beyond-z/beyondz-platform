class Coach::TasksController < Coach::ApplicationController
  def show
    coach_home(nil, params[:id])
    render '/coach/home/index'
  end

  def show
    @coaches_comments = []
    @task = Task.find(params[:id])
    @assignment = @task.assignment
    @next_task = @task.next
    @previous_task = @task.previous

    @previous_task_url = @previous_task ? coach_student_task_path(@previous_task.user_id, @previous_task) : nil
    @next_task_url = @next_task ? coach_student_task_path(@next_task.user_id, @next_task) : nil
  end


  def update
    task = Task.find(params[:id])

    raise ApplicationHelper::PermissionDenied if task.user.coach.id != current_user.id

    if params[:task_state] == 'request_revision'
      task.request_revision!
    elsif params[:task_state] == 'approve'
      if task.submittable?
        task.submit! # to support approve without waiting for the user (this may be a misfeature, we should talk about it)
      end
      task.approve!
    else
      raise "unknown action #{params[:task_state]}"
    end

    task.save!

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { render json: { success: true } }
    end
  end


end
