class Coach::StudentsController < Coach::ApplicationController
  def show
    coach_home(params[:id])
    render "coach/home/index"
  end
end
