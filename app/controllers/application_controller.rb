class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Setup user information for all controllers
  before_action :prepare_user_info

  attr_reader :current_user

  private

    # use controller specific JS whene requested
    # use: before_action :use_controller_js
  def use_controller_js
    @controller_js = params[:controller]
  end

  def prepare_user_info
    if session['user_id']
      @user_logged_in = true
      @current_user = User.find(session['user_id'].to_i)
    else
      @user_logged_in = false
      @current_user = nil
    end
  end


  def require_student
    unless @user_logged_in
      flash[:error] = 'Please log in to see your assignments.'
      redirect_to users_login_path(:redirect_to => assignments_path)
    end
  end

  def require_coach
    unless @user_logged_in && current_user.coach?
      flash[:error] = 'Please log in to see your coaching dashboard.'
      redirect_to users_login_path(:redirect_to => coach_root_path)
    end
  end

end
