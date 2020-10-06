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

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || super
  end

end
