#!/bin/bash
if [ -e /app/tmp/pids/server.pid ]; then
  echo "Cleaning up previous server state"
  rm /app/tmp/pids/server.pid
fi

bundle exec bin/rails s -p 3001 -b '0.0.0.0'
