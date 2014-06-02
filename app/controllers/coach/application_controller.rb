class Coach::ApplicationController < ApplicationController
  before_action :require_coach

  def coach_home(student_filter = nil, assignment_filter = nil)
    @students = current_user.students
    @activity = []
    @focused_student = nil
    @focused_assignment = nil
    @students.each do |student|
      if student_filter
        if student_filter.to_i != student.id
          next
        end
        @focused_student = student
      end
      student.recent_task_activity.each do |ra|
        if assignment_filter
          if assignment_filter.to_i != ra.assignment.assignment_definition_id
            next
          end
          @focused_assignment = ra.assignment.assignment_definition
        end
        unless ra.complete?
          @activity.push(ra)
        end
      end
    end
    @activity = @activity.sort_by { |h| h[:time_ago] }
    @activity.reverse!

    @assignment_definitions = AssignmentDefinition.all
  end
end
