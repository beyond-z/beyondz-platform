require 'digest/sha1';

class User < ActiveRecord::Base
  has_many :user_todos

  def new
  end

  def create
  end

  # Returns the user ID of the matching user if the credentials
  # pass, otherwise, raises a LoginException
  def self.login(email, passw)
    user = User.find_by email: email
    if user == nil
      raise LoginException.new("Incorrect email address")
    else
      parts = user.password.split("-")
      salt = parts[0]
      if parts[1] == User.hash_password(salt, passw)
        return user.id
      else
        raise LoginException.new("Incorrect password")
      end
    end
  end

  # Prepares a reset token for the account with the given
  # email address and sends an email with the given link.
  def self.forgot_password(email, reset_link)
    user = User.find_by email: email
    if user == nil
      raise LoginException.new("Incorrect email address")
    else
      # create a random string of characters to use as the token
      user.reset_token = User.random_string()
      user.reset_expiration = Time.now + 15.minutes
      user.save();

      reset_link += "?token=#{user.reset_token}&id=#{user.id}"
      Notifications.forgot_password(email, user.name, reset_link).deliver
    end
  end

  def self.send_reminders
    next_assignment = Assignment.next_due

    User.all.each do |user|
      total_count = 0;
      total_done = 0;
      next_assignment.todos.each do |todo|
        total_count+=1
        user.user_todos.each do |status|
          if status.todo_id == todo.id && status.completed
           total_done+=1
          end
        end
      end
      if total_count != total_done
        Reminders.assignment_nearly_due(user.email, user.name, "http://platform.beyondz.org/").deliver
      end
    end
  end

  # Returns a random string of 8 upper-case letters
  def self.random_string
    return (0...8).map { (65 + rand(26)).chr }.join
  end

  # Changes the user's password. Don't forget to call save afterward
  def change_password(newPassword, confirmPassword)
    if(newPassword != confirmPassword)
      raise LoginException.new("Your passwords don't match, please try again.")
    end

    self.password = User.get_salted_password(newPassword)
  end

  def self.get_salted_password(passw)
    # Randomization for password hash
    salt = User.random_string()
    return salt + "-" + User.hash_password(salt, passw)
  end

  def self.hash_password(salt, passw)
    return Digest::SHA1.hexdigest("#{salt}#{passw}")
  end
end

class LoginException < Exception
  def initialize(message)
    @message = message
  end

  def message
    @message
  end
end
