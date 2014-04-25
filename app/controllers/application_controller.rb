class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Setup user information for all controllers
  before_filter :prepare_user_info

  private

  def prepare_user_info
    if session['user_id']
      @user_logged_in = true
      @current_user = User.find(session['user_id'].to_i)
    else
      @user_logged_in = false
      @current_user = nil
    end
  end

  public

  attr_reader :current_user
end
