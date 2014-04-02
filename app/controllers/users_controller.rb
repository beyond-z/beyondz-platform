require 'digest/sha1';

class UsersController < ApplicationController
  def login
     email = params[:email]
     passw = params[:password]
     user = User.find_by email: email
     if user == nil
        # bad email
        raise "bad email"
     else
        parts = user.password.split("-")
        salt = parts[0]
        if parts[1] == Digest::SHA1.hexdigest("#{salt}#{passw}")
            session[:user_id] = user.id
        else
            # bad password
            raise "bad password"
        end
     end
     redirect_to "/"
  end
end
