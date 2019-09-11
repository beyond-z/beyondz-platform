#!/bin/bash

# When you stop the container, it doesn't clean itself up properly so it fails to start next time. Cleanup!
if [ -e /app/tmp/pids/server.pid ]; then
  echo "Cleaning up previous server state"
  rm /app/tmp/pids/server.pid
fi

# This is just to make sure we have the docker one there and not something left over, b/c 
# .env takes precedence over the env_file directive in docker-compose.yml
cp -a /app/docker-compose/.env-docker /app/.env

# Here is a command to create an empty database with just the stuff in db:seed. We don't do this in
# here b/c it would be run everytime docker starts when we only need to create/populate the database
# once or on demand.
#bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:seed
echo "###"
echo "If this is the first time building this and you havent created/populated your database yet, run these commands:"
echo ""
echo "docker-compose exec joinweb bundle exec rake db:create"
echo "./docker-compose/scripts/dbrefresh.sh"
echo ""

echo "Starting rails app. Go to http://joinweb:3001 (assuming joinweb is in /etc/hosts on the host machine)"
bundle exec bin/rails s -p 3001 -b '0.0.0.0'
