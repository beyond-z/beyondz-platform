class SessionsController < Devise::SessionsController
  def new
    if params['plain_login']
      super
    else
      # we don't need this to appear on the site since the SSO
      # redirect prompts them to log in via the separate server.
      # they'd see it twice if we didn't clear!
      flash[:error] = nil
      redirect_to new_sso_user_session_path
    end
  end
end
