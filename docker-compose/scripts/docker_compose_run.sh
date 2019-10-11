#!/bin/bash

# When you stop the container, it doesn't clean itself up properly so it fails to start next time. Cleanup!
if [ -e /app/tmp/pids/server.pid ]; then
  echo "Cleaning up previous server state"
  rm /app/tmp/pids/server.pid
fi

echo "Checking if the SALESFORCE ENV vars are setup"
if [ -z "$DATABASEDOTCOM_CLIENT_ID" ] || 
   [ -z "$DATABASEDOTCOM_CLIENT_SECRET" ] || 
   [ -z "$SALESFORCE_USERNAME" ] || 
   [ -z "$SALESFORCE_PASSWORD" ] || 
   [ -z "$SALESFORCE_SECURITY_TOKEN" ] || 
   [ -z "$SALESFORCE_MAGIC_TOKEN" ] ; then
  echo "The SALESFORCE related ENV vars arent setup. One of the following is empty: "
  echo ""
  echo "  DATABASEDOTCOM_CLIENT_ID=$DATABASEDOTCOM_CLIENT_ID"
  echo "  DATABASEDOTCOM_CLIENT_SECRET=$DATABASEDOTCOM_CLIENT_SECRET"
  echo "  SALESFORCE_USERNAME=$SALESFORCE_USERNAME"
  echo "  SALESFORCE_PASSWORD=$SALESFORCE_PASSWORD"
  echo "  SALESFORCE_SECURITY_TOKEN=$SALESFORCE_SECURITY_TOKEN"
  echo "  SALESFORCE_MAGIC_TOKEN=$SALESFORCE_MAGIC_TOKEN"
  echo ""
  echo "Please make sure and set these in your shell (e.g. ~/.bash_profile) before starting the container!"
  echo "The values to use are in: https://drive.google.com/a/bebraven.org/file/d/1AiwrCKZ11-BjNxIIP6qfD9B9rQvmfMY2/view?usp=sharing"
  exit 1
else
  echo "Ok!"
fi

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
