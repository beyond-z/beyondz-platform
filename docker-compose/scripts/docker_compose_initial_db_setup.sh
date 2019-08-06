#!/bin/bash

#sleep 15s until db is up and running
sleep 15

# When you stop the container, it doesn't clean itself up properly so it fails to start next time. Cleanup!
if [ -e /app/tmp/pids/server.pid ]; then
  echo "Cleaning up previous server state"
  rm /app/tmp/pids/server.pid
fi

# This is just to make sure we have the docker one there and not something left over, b/c 
# .env takes precedence over the env_file directive in docker-compose.yml
cp -a /app/docker-compose/.env-docker /app/.env

bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:seed
