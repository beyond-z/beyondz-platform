desc "This task is called by the Heroku scheduler add-on"
# https://devcenter.heroku.com/articles/scheduler

task :send_reminders => :environment do
  ChampionContact.send_reminders
end

namespace :heroku do
  namespace :app do
    require 'platform-api'
    
      # Example call: HEROKU_OAUTH_TOKEN=my-token HEROKU_APP_NAME=my-app bundle exec rake heroku:app:restart_dyno[web]
      desc "Restart a dyno."
      task :restart_dyno, [:dyno_name] => :environment do |t, args|

        # Note: get the HEROKU_OAUTH_TOKEN using:
        #   heroku authorizations:create -d "Portal Admin API token" 
        heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])

        # Note: HEROKU_APP_NAME is supposed to be availble on a normal dyno (in addition to Review Apps) after running:
        #   heroku labs:enable runtime-dyno-metadata
        # but it didn't seem to be so I set it manually
        heroku.dyno.restart(ENV['HEROKU_APP_NAME'], args[:dyno_name])

      end

  end # Namespace: app

end # Namespace: heroku

