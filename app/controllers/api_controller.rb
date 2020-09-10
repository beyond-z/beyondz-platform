class ApiController < ActionController::Base
  before_action :check_authorization

  include Response
  include ExceptionHandler

  private

  def check_authorization
    raise ActionController::InvalidAuthenticityToken unless authorized? 
  end

  def authorized?
    false if auth_token.nil?

    Rails.application.secrets.join_api_token.eql?(auth_token)    
  end

  def auth_token
    if auth_header
      auth_header.split(' ')[1]
    end
  end

  def auth_header
    request.headers['Authorization']
  end
end
