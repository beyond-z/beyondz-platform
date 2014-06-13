class ConfirmationsController < Devise::ConfirmationsController

  private

  def after_confirmation_path_for(_resource_name, _resource)
    '/'
  end

end
