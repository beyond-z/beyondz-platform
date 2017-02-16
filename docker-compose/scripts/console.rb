#!/bin/bash
# Put a file called script.rb in the app root and this will execute it in the console
if [ ! -e app ]
then
  echo "Please run this script from the root of the application."
  exit 1;
fi

if [ ! -e script.rb ]
then
  echo "The file 'script.rb' must exist at the root of the application"
  exit 1;
fi

docker-compose -f ../docker-compose-join.yml run --rm joinweb /bin/bash -c "bundle exec rails runner \"eval(File.read '/app/script.rb')\""

