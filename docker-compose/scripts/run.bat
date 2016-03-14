#!/bin/bash

# When you stop the container, it doesn't clean itself up properly so it fails to start next time. Cleanup!
if [ -e /app/tmp/pids/server.pid ]; then
  echo "Cleaning up previous server state"
  rm /app/tmp/pids/server.pid
fi

echo ""
echo "Note: If this is the first time you're starting this container, you may have to run the following:"
echo ""
echo "    bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:seed"

bundle exec bin/rails s -p 3001 -b '0.0.0.0'
