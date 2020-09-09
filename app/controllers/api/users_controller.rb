class Api::UsersController < ApiController
  def create
    @user = User.new(user_params)
    @user.skip_confirmation!
    @user.save!
    # I don't want to use serializers. It'll be overkill for now
    response_data = { id: @user.id }

    json_response response_data, :created
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name)
  end
end
