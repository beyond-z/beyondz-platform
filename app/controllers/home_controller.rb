class HomeController < ApplicationController

  before_action :get_new_user, only: [:coach_info, :student_info, :supporter_info, :others_info]

  layout 'public'

  def index
    if current_user
      if current_user.is_administrator?
        redirect_to admin_root_path
      elsif current_user.coach?
        redirect_to coach_root_path
      else
        redirect_to assignments_path
      end
    end
  end

  def coach_info
  end

  def student_info
  end

  def supporter_info
  end

  def others_info
  end

  private

  def get_new_user
    @new_user = User.find(params[:new_user_id])
  end

end