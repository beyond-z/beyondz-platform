require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :assignments, dependent: :destroy
  has_many :tasks

  has_many :coach_students, foreign_key: :coach_id
  has_many :students, through: :coach_students, :source => :student

  after_create :create_child_skeleton_rows

  def name
    "#{first_name} #{last_name}"
  end

  def coach
    c = CoachStudent.find_by :student_id => id
    if c
      return c.coach
    end
  end

  def coach?
    students.any?
    # user role table FIXME
  end

  # This will create the skeletons for assignments, tasks,
  # and submissions based on the definitions. We should run
  # this whenever a user is created or a definition is added.
  #
  # Don't forget to update this code if we add any more has_many
  # relationships with the same skeleton row pattern.
  def create_child_skeleton_rows
    ActiveRecord::Base.transaction do

      AssignmentDefinition.all.each do |a|
        assignment = assignments.find_by_assignment_definition_id(a.id)
        if assignment.nil?
          assignment = Assignment.create(
            assignment_definition_id: a.id,
            state: 'new'
          )
          assignments << assignment
        end

        a.task_definitions.each do |td|
          task = tasks.find_by_task_definition_id(td.id)
          if task.nil?
            task = Task.create(
              task_definition_id: td.id,
              assignment_id: assignment.id,
              kind: td.kind,
              file_type: td.file_type,
              state: 'new'
            )
            tasks << task
          end
        end
      end

      save!
    end
  end

  def recent_task_activity
    result = []
    tasks.each do |a|
      if a.complete? || a.pending_approval? || (a.comments.any? && !a.complete?)
        result.push(a)
      end
    end
    result = result.sort_by { |h| h[:time_ago] }
    result
  end


  # Returns the user ID of the matching user if the credentials
  # pass, otherwise, raises a LoginException
  def self.login(email, passw)
    user = User.find_by email: email
    if user.nil?
      raise LoginException.new('Incorrect email address')
    else
      parts = user.password.split('-')
      salt = parts[0]
      if parts[1] == User.hash_password(salt, passw)
        # This creates any missing skeleton rows now
        # to ensure all assignments are up to date.
        user.create_child_skeleton_rows
        return user.id
      else
        raise LoginException.new('Incorrect password')
      end
    end
  end

  # Prepares a reset token for the account with the given
  # email address and sends an email with the given link.
  def self.forgot_password(email, reset_link)
    user = User.find_by email: email
    if user.nil?
      raise LoginException.new('Incorrect email address')
    else
      # create a random string of characters to use as the token
      user.reset_token = User.random_string
      user.reset_expiration = Time.now + 15.minutes
      user.save

      reset_link += "?token=#{user.reset_token}&id=#{user.id}"
      Notifications.forgot_password(email, user.name, reset_link).deliver
    end
  end

  def self.send_reminders
    next_assignment = Assignment.next_due

    User.all.each do |user|
      total_count = 0
      total_done = 0
      next_assignment.todos.each do |todo|
        total_count += 1
        user.user_todos.each do |status|
          if status.todo_id == todo.id && status.completed
            total_done += 1
          end
        end
      end
      if total_count != total_done
        Reminders.assignment_nearly_due(
          user.email,
          user.name,
          next_assignment.title,
          'http://platform.beyondz.org/assignments/' +
          next_assignment.seo_name)
            .deliver
      end
    end
  end

  # Returns a random string of 8 upper-case letters
  def self.random_string
    (0...8).map { (65 + rand(26)).chr }.join
  end

  # Changes the user's password. Don't forget to call save afterward
  def change_password(newPassword, confirmPassword)
    if newPassword != confirmPassword
      raise LoginException.new("Your passwords don't match, please try again.")
    end

    self.password = User.get_salted_password(newPassword)
  end

  def self.get_salted_password(passw)
    # Randomization for password hash
    salt = User.random_string
    salt + '-' + User.hash_password(salt, passw)
  end

  def self.hash_password(salt, passw)
    Digest::SHA1.hexdigest("#{salt}#{passw}")
  end
end

class LoginException < Exception
  def initialize(message)
    @message = message
  end

  attr_reader :message
end
