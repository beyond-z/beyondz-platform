#!bin/bash
# Put a file called script.rb in the app root and this will execute it in the console
docker-compose -f ../docker-compose-join.yml run --rm joinweb /bin/bash -c "bundle exec rails runner \"eval(File.read '/app/script.rb')\""
