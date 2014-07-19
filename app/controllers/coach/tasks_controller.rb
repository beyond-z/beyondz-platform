class Coach::TasksController < Coach::ApplicationController

  before_action :use_controller_js

  def show
    coach_home(nil, params[:id])
    render '/coach/home/index'
  end

  def show
    @task = Task.find(params[:id])
    @assignment = @task.assignment
    @next_task = @task.next
    @previous_task = @task.previous
  end


  def update
    @task = Task.find(params[:id])

    raise ApplicationHelper::PermissionDenied if @task.user.coach.id != current_user.id

    if params[:task][:action]
      if params[:task][:action] == 'request_revision'
        @task.request_revision!
      elsif params[:task][:action] == 'approve'
        if @task.submittable?
          @task.submit! # to support approve without waiting for the user (this may be a misfeature, we should talk about it)
        end
        @task.approve!
      else
        raise "unknown action #{params[:task][:action]}"
      end

      @task.save!
    end

    respond_to do |format|
      format.html { render partial: 'coach/tasks/action_box' }
      format.json { render json: { success: true } }
    end
  end


end
