class ConfirmationsController < Devise::ConfirmationsController

  def create
    # For user friendliness: if they are asking for a token to be sent to an email
    # which is already confirmed, redirect them automatically and prompt them to sign in
    user = User.find_for_database_authentication(:email => params[:user][:email])
    if !user.nil? && user.confirmed?
      path = after_resending_confirmation_instructions_path_for(resource_name)
      path += "?email=#{URI.encode_www_form_component(params[:user][:email])}"
      flash[:notice] = 'You are already confirmed. Please try signing in'
      respond_with({}, :location => path)
    else
      # Otherwise, keep the behavior the same
      super
    end
  end


  private

  def after_confirmation_path_for(resource_name, resource)
    sign_in(resource_name, resource)

    # If we set up a salesforce account, create the user/contact there
    # too. If not, we'll skip that step so we don't get exceptions from
    # the salesforce api about bad credentials and instead just keep it
    # all locally.
    if Rails.application.secrets.salesforce_username
      current_user.create_on_salesforce
    end

    StaffNotifications.new_user(current_user).deliver

    flash[:notice] = nil
    redirect_to_welcome_path(current_user)
  end

end
