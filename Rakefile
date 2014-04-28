# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

# Import all environment variables from the .env file
if Rails.env.development? && File.exist?('.env')
	env_vars = File.read('.env').scan /(export)?\s+(\S+)=(\S+)/
	env_vars.each { |v| ENV[v[1]] = v[2].gsub /\A['"]|['"]\Z/, '' }
end

BeyondzPlatform::Application.load_tasks
