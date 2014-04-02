class ProgramsController < ApplicationController
  def college
    if session["user_id"] != nil
      @user_logged_in = true
      @user = User.find(session["user_id"].to_i)
    else
      @user_logged_in = false
    end
  end
end
