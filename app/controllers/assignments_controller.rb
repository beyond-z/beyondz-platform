class AssignmentsController < ApplicationController
  def index
    user = User.find(session[:user_id])

    @incomplete_assignments = user.assignments.incomplete
    @complete_assignments = user.assignments.complete.reverse
  end

  def completed
    index
  end

  def set_completed
    if request.post?
      todo = Todo.find(params[:id])
      todo.update_attribute(:completed, params[:completed])
    end
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end

end
