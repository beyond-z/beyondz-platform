#!/bin/zsh

docker-compose up -d
docker-compose exec joinweb bundle exec rake db:create 
./docker-compose/scripts/dbrefresh.sh
