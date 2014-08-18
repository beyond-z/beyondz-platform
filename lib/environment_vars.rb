class EnvironmentVars

  # Load all enviroment variables from ".env" into ENV.
	def self.load_env
    env_file = File.join(Rails.root, '.env')
    if File.exist?(env_file)
    # look for variable declaration with optional "export"
      env_vars = File.read(env_file).scan /(export)?\s+(\S+)=(\S+)/
      env_vars.each { |v| ENV[v[1]] = v[2].gsub /\A['"]|['"]\Z/, '' }
    end
	end
end
