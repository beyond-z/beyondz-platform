#!/bin/bash
docker-compose down

# If you want to really blow it all away, uncomment this:
#docker-compose build --no-cache

docker-compose up -d --force-recreate
