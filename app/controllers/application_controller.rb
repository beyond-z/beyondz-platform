class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  layout :default_layout
  before_action :save_external_referrer
  before_action :permit_lms_iframe
  before_filter :check_domain

  private

  # Allows all permutations of http://beyondz.org, http://www.beyondz.org, https://beyondz.org, and https://www.beyondz.org
  # when configured as discussed here: http://stackoverflow.com/questions/6701549/heroku-ssl-on-root-domain
  def check_domain
    if Rails.env.production? and request.subdomain.downcase == 'www'
      redirect_to request.protocol + request.domain + request.fullpath, :status => 301
    end
  end

  def permit_lms_iframe
    secure = Rails.application.secrets.canvas_use_ssl ? 's' : ''
    domain = Rails.application.secrets.canvas_server
    port   = Rails.application.secrets.canvas_port
    if (secure && port != 443) || (!secure && port != 80)
      port = ":#{port}"
    else
      port = ''
    end

    response.headers['X-Frame-Options'] = "Allow-From http#{secure}://#{domain}#{port}"
  end

  def save_external_referrer
    if session[:referrer].nil?
      session[:referrer] = request.referrer
    end
  end

  # see: http://stackoverflow.com/questions/4982073/different-layout-for-sign-in-action-in-devise
  def default_layout
    if devise_controller?
      'public'
    else
      'application'
    end
  end

  # use controller specific JS whene requested
  # use: before_action :use_controller_js
  def use_controller_js
    @controller_js = params[:controller].split('/')[-1]
  end

  def require_student
    unless user_signed_in?
      flash[:error] = 'Please log in to see your assignments.'
      redirect_to new_user_session_path
    end
  end

  def require_coach
    unless user_signed_in? && current_user.coach?
      flash[:error] = 'Please log in to see your coaching dashboard.'
      redirect_to new_user_session_path
    end
  end

  # direct users to the proper path upon registration
  # We are now sending them all to a generic page, but I'm
  # keeping this method because we might change our mind back
  # and then we'd do to undo just to redo...
  def redirect_to_welcome_path(user)
    welcome_path(new_user_id: user.id)
  end

end
