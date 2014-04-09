class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Setup user information for all controllers
  before_filter :prepareUserInfo
  def prepareUserInfo
    if session["user_id"] != nil
      @user_logged_in = true
      @user = User.find(session["user_id"].to_i)
    else
      @user_logged_in = false
    end
  end

end
