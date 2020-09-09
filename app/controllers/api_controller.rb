class ApiController < ActionController::Base
  NotAuthorized = Class.new(StandardError)

  before_action :check_authorization

  include Response
  include ExceptionHandler

  private

  def check_authorization
    raise NotAuthorized unless authorized? 
  end

  def authorized?
    false if auth_token.nil?

    Rails.application.secrets.api_conn_key.eql?(auth_token)    
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
