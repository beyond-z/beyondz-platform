class Coach::UsersController < Coach::ApplicationController
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
    @user = User.create(params[:user].permit(:first_name, :last_name, :email, :password))
    # Since the password coming from the User.create is not uniquely salted,
    # we'll call the change_password method immediately to ensure it is
    # stored correctly and securely.
    @user.change_password(params[:user][:password], params[:user][:password])
    @user.save!
    redirect_to "/admin/users"
  end
end
