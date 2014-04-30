class Admin::ApplicationController < ApplicationController
  before_action :require_login

  private

  def require_login
    unless @user_logged_in
      flash[:error] = "You must log in to access the admin."
      redirect_to "/users/login?redirect_to=/admin/"
      return
    end
    unless current_user.is_administrator
      flash[:error] = "Please log in with your admin account."
      redirect_to "/users/login?redirect_to=/admin/"
      return
    end
  end
end
