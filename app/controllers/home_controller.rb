class HomeController < ApplicationController

  before_action :new_user, only: [:welcome, :volunteer, :apply, :partner]

  layout 'public'

  def index
    if current_user
      if current_user.is_administrator?
        redirect_to admin_root_path
      elsif current_user.coach?
        redirect_to coach_root_path
      elsif current_user.student?
        redirect_to assignments_path
      else
        # This is a logged in user who is not yet
        # accepted into the program - we'll give them
        # the welcome screen so they can learn more.
        redirect_to welcome_path
      end
    end
    # Otherwise, non-logged in users
    # just get the public home page
    # via the home/index view
  end

  def welcome
  end

  def volunteer
  end

  def apply
  end

  def supporter_info
  end

  def partner
  end

  def jobs
  end

  private

  def new_user
    if params[:new_user_id]
      @new_user = User.find(params[:new_user_id])
    end
  end

end
