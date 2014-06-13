class EnrollmentsController < ApplicationController

  layout 'public'

  def index

  end

  def new
    @user = User.new
  end

  def create
    user = params[:user].permit(:first_name, :last_name, :email, :password, :applicant_type)
    @new_user = User.create(user)
    # sign_in(:user, @new_user)
  end

end
