class AssignmentsController < ApplicationController
  def index
    @assignments = Assignment.all

    @assignments_completed = Hash.new

    if @user_logged_in
      # We want to get a hash of to-do check status for easy
      # lookup in the view
      @user_todos = Hash.new
      user = User.find(session[:user_id])
      user.user_todos.each do |s|
        @user_todos[s.todo_id] = s.completed
      end

      # We'll also use it to see if all to-dos are done
      # which the view can use to collapse an entry

      @assignments.each do |assignment|
        all_checked = true
        assignment.todos.each do |todo|
          if !@user_todos[todo.id]
            all_checked = false
            break
          end
        end

        if all_checked
          @assignments_completed[assignment.id] = true
        end
      end # assignments.each
    end # if user logged in
  end

  def set_completed
    if request.post?
      user = User.find(session[:user_id])
      user.user_todos.each do |s|
        if s.todo_id == params[:id]
          s.completed = params[:completed]
          s.save
          return
        end
      end

      # wasn't found in the existing list, time to create a new entry
      user.user_todos.push(UserTodo.create(
          :completed_at => Time.now,
          :todo_id => params[:id],
          :completed => params[:completed],
          :user_id => user.id
      ))
    end
  end

  # All of the assignments details are static routes defined in routes.rb for now. assignment for now.  In Phase 2, we'll fix this up.

end
