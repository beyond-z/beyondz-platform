#!/bin/zsh
echo "Refreshing your local dev database"

app=${1:-boiling-plateau-9467}
./docker-compose/scripts/dblatest_download.sh $app
./docker-compose/scripts/dblatest_restore.sh
