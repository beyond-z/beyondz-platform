require 'digest/sha1';

class UsersController < ApplicationController
    def login_page
        login_form(params[:email], nil)
    end

    def login_form(email, message)
        @user = User.new
        @email = email
        @message = message
        render action: 'form'
    end

    def forgotPassword
        # returns the form
    end

    def passwordEmailSent
        # view only
    end

    def doForgotPassword
        email = params[:email]

        begin
            User.forgotPassword(email)
            redirect_to "/users/password-email-sent"
            rescue LoginException => e
                @message = "That email address isn't on file. If you can't remember the email address you use to log in, please contact support."
                render :forgotPassword
        end
    end

    def logout
        session[:user_id] = nil
        render :logged_out
    end

    def login
        userInfo = params[:user]
        begin
            user = User.new
            session[:user_id] = user.login(userInfo[:email], userInfo[:password])
            redirect_to "/"
            rescue LoginException => e
                login_form(userInfo[:email], e.type)
        end
    end
end
