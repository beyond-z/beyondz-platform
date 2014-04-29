class Admin::UsersController < Admin::ApplicationController
  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def create
    if @user = User.create(params[:user].permit(:first_name, :last_name, :email, :name, :password))
      @user.create_child_skeleton_rows
      @user.change_password(params[:user][:password], params[:user][:password])
      @user.save!
      redirect_to "/admin/users"
    else
      # error
    end
  end
end
