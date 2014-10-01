source 'https://rubygems.org'

ruby "2.1.1"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.0'

# Use postgresql as the database for Active Record
gem 'pg'

# group :production do
# end

# Let's use Twitter Boostrap.
gem 'bootstrap-sass'
group :development do
  gem 'rails_layout'
  # Use debugger
  gem 'byebug'
  gem 'better_errors'
  # used with 'better_errors'
  gem 'binding_of_caller'
end

group :development, :test do
  # makes creating complex objects easier in tests
  gem 'factory_girl_rails'
  # allows for user browser simulation in integration testing
  gem 'capybara'
end

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

# Acts As State Machine
gem 'aasm', '~> 3.1.1'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Heroku needs this since the Rails plugin system was removed in Ruby 4.
gem 'rails_12factor', group: :production

# We are submitting assignments by inserting them into a Google Spreadsheet.
# This gem makes it easy to read/write these sheets.
gem 'google_drive'

# JSON parsing
gem 'json'

# File attachements
gem 'paperclip'

# Used by paperclip S3 storage
gem 'aws-sdk', '~> 1.5.8'

# Rubocop code checker
gem 'rubocop'

# export to excel (xls)
gem 'to_xls-rails'

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

gem 'devise'

gem 'devise_cas_authenticatable'
