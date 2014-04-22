class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Setup user information for all controllers
  before_filter :prepare_user_info
  private
  def prepare_user_info
    if session["user_id"] != nil
      @user_logged_in = true
      @user = User.find(session["user_id"].to_i)
    else
      @user_logged_in = false
      @user = nil
    end
  end

  public
  def current_user
    return @user
  end
end
