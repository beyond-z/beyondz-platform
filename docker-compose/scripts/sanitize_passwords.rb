# Sets all passwords to test1234.  To do this on staging, just run:
# cat sanitize_passwords.rb | heroku run rails console --app <staging_app>
#
# OR on localhost
# cat sanitize_passwords.rb | bundle exec rails console
#
# BE VERY CAREFUL.  If you run this on a real server, you'll wipe all the passwords!
User.all.each do |user|
  user.password = 'test1234'
  user.save!
end

exit
