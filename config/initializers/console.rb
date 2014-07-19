# Rails console doesn't automatically pull in ENV vars from '.env'.
# Load them here to ensure they are loaded explicitly.
EnvironmentVars.load_env if (Rails.env.development? || Rails.env.test?)