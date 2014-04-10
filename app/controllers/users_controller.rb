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

  def resetPassword
    user = User.find(params[:id])
    if user == nil
      @message = "Your user is wrong"
      render action: :forgotPassword
      return
    end

    if user.reset_token != params[:token]
      @message = "Your link has expired, please try again."
      render action: :forgotPassword
      return
    end

    if user.reset_expiration < Time.now
      @message = "Your link has expired, please try again."
      render action: :forgotPassword
      return
    end

    user.reset_token = ""
    user.reset_expiration = Time.now
    user.save;

    # log in immediately with the reset token and send
    # them to change their password now
    session[:user_id] = user.id
    redirect_to "/users/change-password"
  end

  def changePassword
      # view
  end

  def doChangePassword
    begin
      user = User.find(session[:user_id])
      user.changePassword(params[:password], params[:confirm_password]);
      user.save;

      redirect_to("/users/password-changed")
    rescue LoginException => e
      @message = e.type # "Your passwords didn't match, please try again."
      render :changePassword
    end
  end

  def passwordChanged
    #view
  end

  def doForgotPassword
    email = params[:email]

    begin
      User.forgotPassword(email, "http://#{request.host}/users/reset-password")
      redirect_to "/users/password-email-sent"
      rescue LoginException => e
        @message = "That email address isn't on file. If you can't remember the email address you use to log in, please contact tech@beyondz.org."
        render :forgotPassword
    end
  end

  def logout
    session[:user_id] = nil
    flash[:message] = "You have been successfully logged out."
    redirect_to "/"
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
