class Coach::AssignmentsController < Coach::ApplicationController
  def show
    coach_home(nil, params[:id])
    render '/coach/home/index'
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
