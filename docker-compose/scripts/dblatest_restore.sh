#!/bin/bash
echo "Refreshing your local dev database from the recent download"

docker-compose down
docker-compose up -d joindb

echo "DROP SCHEMA public CASCADE;" | docker-compose exec -T joindb psql -U postgres -d joindb
echo "CREATE SCHEMA public;" | docker-compose exec -T joindb psql -U postgres -d joindb

docker-compose exec joindb pg_restore --jobs 1 --no-acl --no-owner -U postgres -d joindb /latest.dump

# This is our normal test password for everyone. I got this by loading a staging db with the security keys 
# and stuff we use, then setting someones password to the test one in the rails console.
ENCRYPTED_TEST_PASS='$2a$10$C2W0hszrbmpk8tkw0ViLFOXVFH1Sj6HAiMyGah6vdEoRUj7GK1KzO'
echo "UPDATE users SET encrypted_password = '$ENCRYPTED_TEST_PASS';" | docker-compose exec -T joindb psql -U postgres joindb
