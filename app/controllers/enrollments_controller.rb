class EnrollmentsController < ApplicationController

  layout 'public'

  def index

  end

  def new
    @user = User.new
  end

  def create
    user = params[:user].permit(:first_name, :last_name, :email, :password)
    @new_user = User.create(user)
    @new_user.applicant_type = params[:type]
    @new_user.email = user[:email]
    @new_user.save!

    @new_user_type = params[:type]
    sign_in(:user, @new_user)
  end

end
