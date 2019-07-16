FROM ruby:2.2.3

#fix for jessie repo eol issues
RUN echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
RUN sed -i '/deb http:\/\/httpredir.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list

RUN apt-get -o Acquire::Check-Valid-Until=false update -yqq && apt-get install -y build-essential libpq-dev postgresql-client vim gettext

RUN mkdir /app
WORKDIR /app

COPY Gemfile* /app/
RUN bundle install

# Do this after bundle install b/c if we do it before then changing any files 
# causes bundle install to be invalidated and run again on the next build
COPY . /app

CMD ["foreman", "start"]
