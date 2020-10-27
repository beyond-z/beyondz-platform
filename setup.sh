#!/bin/zsh

docker-compose down
rm -rf latest.dump*
./docker-compose/scripts/dblatest_download.sh

docker volume rm beyondz-platform_db-data
docker-compose up -d joindb
sleep 5
docker-compose run joinweb bundle exec rake db:create
./docker-compose/scripts/dblatest_restore.sh
./docker-compose/scripts/dblatest_restore.sh # first time, some errors. second time, not so much.

docker-compose down
docker-compose up -d
