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

  def forgot_password
      # returns the form
  end

  def password_email_sent
      # view only
  end

  def reset_password
    begin
      user = User.find(params[:id])

      if user.reset_token != params[:token] || user.reset_expiration < Time.now
        raise LoginException.new("Your link has expired, please try again.")
      end

      rescue LoginException => e
        @message = e.message
        render action: :forgot_password
        return
      rescue ActiveRecord::RecordNotFound => e
        @message = "Your user account could not be found, be sure you copied the link correctly out of the email."
        render action: :forgot_password
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

  def change_password
      if request.post?
        begin
          user = User.find(session[:user_id])
          user.change_password(params[:password], params[:confirm_password]);
          user.save;

          redirect_to("/users/password-changed")
        rescue LoginException => e
          @message = e.message
          render :change_password
        end
      end
      # otherwise, it will display the view automatically
  end

  def password_changed
    #view
  end

  def do_forgot_password
    email = params[:email]

    begin
      User.forgot_password(email, "http://#{request.host}/users/reset-password")
      redirect_to "/users/password-email-sent"
      rescue LoginException => e
        @message = "That email address isn't on file. If you can't remember the email address you use to log in, please contact tech@beyondz.org."
        render :forgot_password
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
        login_form(userInfo[:email], e.message)
    end
  end
end
