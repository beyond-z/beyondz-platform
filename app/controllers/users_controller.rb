require 'digest/sha1';

class UsersController < ApplicationController
  def login_page
    @user = User.new
    @message = nil
    if params[:message] == "bad_email"
        @message = "Your email address was incorrect."
    end
    if params[:message] == "bad_password"
        @message = "Your password was incorrect."
    end
    render action: 'form'
  end

  def login
     email = params[:email]
     passw = params[:password]
     user = User.find_by email: email
     if user == nil
        # bad email
        redirect_to "/users/login?message=bad_email"
        return
     else
        parts = user.password.split("-")
        salt = parts[0]
        if parts[1] == Digest::SHA1.hexdigest("#{salt}#{passw}")
            session[:user_id] = user.id
        else
            # bad password
            redirect_to "/users/login?message=bad_password&email=" + email
            return
        end
     end
     redirect_to "/"
  end
end
