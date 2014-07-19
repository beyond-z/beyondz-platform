class Admin::ApplicationController < ApplicationController
  before_action :require_admin

  layout 'admin'

  private

  def require_admin
    unless user_signed_in?
      flash[:error] = 'You must log in to access the admin section.'
      redirect_to new_user_session_path
      return
    end
    unless current_user.is_administrator?
      flash[:error] = 'Please log in with your admin account.'
      redirect_to new_user_session_path
      return
    end
  end
end
