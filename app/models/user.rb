class LoginException < Exception
	def initialize(type)
		@type = type
	end

	def type
		@type
	end
end

class User < ActiveRecord::Base
    def new
    end

    def create
    end

    def login(email, passw)
        user = User.find_by email: email
        if user == nil
            raise LoginException.new("Incorrect email address")
        else
            parts = user.password.split("-")
            salt = parts[0]
            if parts[1] == hashPassword(salt, passw)
                return user.id
            else
                raise LoginException.new("Incorrect password")
            end
        end
    end

    def self.forgotPassword(email)
        user = User.find_by email: email
        if user == nil
            raise LoginException.new("Incorrect email address")
        else
            newpw = (0...8).map { (65 + rand(26)).chr }.join
            user.changePassword(newpw, newpw)
            user.save();
            Notifications.forgot_password(email, user.name, newpw).deliver
        end
    end

    def changePassword(newPassword, confirmPassword)
        if(newPassword != confirmPassword)
            raise "passwords don't match"
        end

        salt = (0...8).map { (65 + rand(26)).chr }.join
        self.password = salt + "-" + hashPassword(salt, newPassword)
    end

    def hashPassword(salt, passw)
            return Digest::SHA1.hexdigest("#{salt}#{passw}")
    end
end
