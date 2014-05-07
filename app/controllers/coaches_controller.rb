class CoachesController < ApplicationController
  before_action :require_coach_login

  public

  def index
    @students = current_user.students
    @activity = []
    @students.each do |student|
      student.recent_task_activity.each do |ra|
        if !ra.complete?
          @activity.push(ra)
        end
      end
    end
    @activity = @activity.sort_by { |h| h[:time_ago] }
    @activity.reverse!
  end

  def approve_task
    task = Task.find(params[:task][:id])
    task.approve!
    task.save!

    respond_to do |format|
      format.html { redirect_to "/coaches" }
      format.json { render json: { success: true } }
    end
  end

  def request_task_revisions
    task = Task.find(params[:task][:id])
    task.request_revision!
    task.save!

    respond_to do |format|
      format.html { redirect_to "/coaches" }
      format.json { render json: { success: true } }
    end
  end

end
