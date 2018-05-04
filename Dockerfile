FROM ruby:2.2.3

RUN apt-get update -yqq && apt-get install -y build-essential libpq-dev postgresql-client vim

RUN mkdir /app
WORKDIR /app

COPY Gemfile* /app/
RUN bundle install

# Do this after bundle install b/c if we do it before then changing any files 
# causes bundle install to be invalidated and run again on the next build
COPY . /app

CMD ["foreman", "start"]