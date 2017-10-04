desc "This task is called by the Heroku scheduler add-on"

task :send_reminders => :environment do
  ChampionContact.send_reminders
end

# https://devcenter.heroku.com/articles/scheduler
