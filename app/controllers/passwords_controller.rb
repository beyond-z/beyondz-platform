class PasswordsController < Devise::PasswordsController
  def set_flash_message(_key, kind, options = {})
    message = find_message(kind, options)
    cookies['login_flash'] = {
      :value => message,
      # We want this to be seen on the sso.bebraven.org (or stagingsso.bebraven.org)
      # but can't set the cookie directly there - best we can do is to set to
      # bebraven.org (note: staging.bebraven.org will NOT work as that won't
      # include stagingsso.bebraven.org - where it needs to be.
      :domain => Rails.application.secrets.cookie_domain
    }
  end
end
