class AssignmentsController < ApplicationController
  def get_temp
    #assignment = Assignment.new
    #assignment.id = 1
    #assignment.title = "Test Assignment"
    #assignment.led_by = "staff"
    #assignment.start_date = Time.now - 7.days
    #assignment.end_date = Time.now + 7.days
    #assignment.front_page_info = "Cool <b>html</b>"
    #assignment.details_summary = "Summery here"
    #assignment.save
    @assignment = Assignment.find(1)
    #@assignment.todos.push(Todo.create(:content => "Cool"))
  end
  
  # All of the assignments details are static routes defined in routes.rb for now. assignment for now.  In Phase 2, we'll fix this up.

end
