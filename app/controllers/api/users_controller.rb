class Api::UsersController < ApiController
  def index
    @users = User.where(email: params[:q])

    json_response @users
  end

  def create
    @user = User.new(user_params)
    @user.skip_confirmation!
    @user.save!

    json_response @user, :created
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name)
  end
end
