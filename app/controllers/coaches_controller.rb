class CoachesController < ApplicationController
  before_action :require_coach_login

  public

  def index
    @students = current_user.students
    @activity = []
    @focused_student = nil
    @focused_assignment = nil
    @students.each do |student|
      if params[:student_id]
        if params[:student_id].to_i != student.id
          next
        end
        @focused_student = student
      end
      student.recent_task_activity.each do |ra|
        if params[:assignment_id]
          if params[:assignment_id].to_i != ra.assignment.assignment_definition_id
            next
          end
          @focused_assignment = ra.assignment.assignment_definition
        end
        if !ra.complete?
          @activity.push(ra)
        end
      end
    end
    @activity = @activity.sort_by { |h| h[:time_ago] }
    @activity.reverse!

    @assignment_definitions = AssignmentDefinition.all
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
