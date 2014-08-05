class ConfirmationsController < Devise::ConfirmationsController

  private

  def after_confirmation_path_for(resource_name, resource)
    sign_in(resource_name, resource)

    StaffNotifications.new_enrollment(current_user).deliver

    flash[:notice] = nil
    redirect_to_welcome_path(current_user)
  end

end
