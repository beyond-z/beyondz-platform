class Coach::AssignmentsController < Coach::ApplicationController
  def index
    coach_home(nil, params[:id])
    render '/coach/home/index'
  end

  def show
    @assignment = Assignment.find(params[:id])

    tasks = @assignment.tasks.need_coach_attention
    unless tasks.any?
      tasks = @assignment.tasks
    end

    @task = tasks.first
    @next_task = @task.next
    @previous_task = @task.previous
  end

  def update
    assignment = Assignment.find(params[:id])

    if params[:approve] && (params[:approve] == 'true')
      if assignment.user.coach == current_user
        assignment.approve!
        redirect_to coaches_path
        return
      end
    end
  end

end
