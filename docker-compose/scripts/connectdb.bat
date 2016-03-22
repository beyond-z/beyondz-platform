#!/bin/bash
docker-compose run --rm joinweb psql -h joindb -U postgres -d postgres
