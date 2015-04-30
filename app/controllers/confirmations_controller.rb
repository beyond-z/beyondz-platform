class ConfirmationsController < Devise::ConfirmationsController
  # See also: passwords_controller.rb for the same function, but
  # this one needs to be able to take a custom message too and
  # preserve the original behavior in some cases.
  def set_flash_message(_key, kind, options = {}, message = nil)
    message = find_message(kind, options) if message.nil?
    cookies['login_flash'] = {
      :value => message,
      # We want this to be seen on the sso.beyondz.org (or stagingsso.beyondz.org)
      # but can't set the cookie directly there - best we can do is to set to
      # beyondz.org (note: staging.beyondz.org will NOT work as that won't
      # include stagingsso.beyondz.org - where it needs to be. So no need to
      # configure it - there is only one correct setting possible.
      :domain => '.beyondz.org'
    }

    super(_key, kind, options) unless _key.nil?
  end


  def new
    super
    if params[:email]
      @prefill_email = params[:email]
    end
    @auto_submit = params[:auto]
  end

  def create
    # For user friendliness: if they are asking for a token to be sent to an email
    # which is already confirmed, redirect them automatically and prompt them to sign in
    user = User.find_for_database_authentication(:email => params[:user][:email])
    if !user.nil? && user.confirmed?
      path = after_resending_confirmation_instructions_path_for(resource_name)
      path += "?email=#{URI.encode_www_form_component(params[:user][:email])}"
      set_flash_message(nil, nil, {}, 'You are already confirmed. Please try signing in')
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
