#!/bin/bash

# When you stop the container, it doesn't clean itself up properly so it fails to start next time. Cleanup!
if [ -e /app/tmp/pids/server.pid ]; then
  echo "Cleaning up previous server state"
  rm /app/tmp/pids/server.pid
fi

cp -a /app/docker-compose/config/* /app/config/
cp -a /app/docker-compose/.env-docker /app/.env

envsubst < /app/docker-compose/config/database.yml > /app/config/database.yml

# check if database is provisioned or not
if [[ $(psql -lqt -h joindb -p 5432 -U postgres postgres | cut -d \| -f 1 | grep -i beyondz | wc -l) = 0 ]]; then
  bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:seed
fi

bundle exec bin/rails s -p 3001 -b '0.0.0.0'
