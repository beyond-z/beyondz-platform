# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

# Rake doesn't automatically pull in ENV vars from '.env'.
# Need to require this, since rake environment is not loaded yet.
require 'environment_vars'
EnvironmentVars.load_env if (Rails.env.development? || Rails.env.test?)

BeyondzPlatform::Application.load_tasks
