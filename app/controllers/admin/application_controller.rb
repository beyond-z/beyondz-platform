class Admin::ApplicationController < ApplicationController
  before_action :require_login

  private

  def require_login
    unless @user_logged_in
      flash[:error] = "You must log in to access the admin."
      redirect_to "/users/login?redirect_to=/admin/"
    end
  end
end
