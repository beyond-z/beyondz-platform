class SessionsController < Devise::SessionsController
  def new
    if params['plain_login']
      super
    else
      redirect_to new_sso_user_session_path
    end
  end
end
