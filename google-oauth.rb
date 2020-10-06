# This script is used to create the refresh token for
# the GOOGLE_SPREADSHEET_REFRESH_TOKEN setting
# See the instructions in env.sample for how to use it.

require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'

APPLICATION_NAME = 'Salesforce To Google Docs Integration'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join("google_credentials.json")
SCOPE = 'https://www.googleapis.com/auth/calendar https://spreadsheets.google.com/feeds https://www.googleapis.com/auth/drive'

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization request via InstalledAppFlow.
# If authorization is required, the user's default browser will be launched
# to approve the request.
#
# @return [Signet::OAuth2::Client] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  file_store = Google::APIClient::FileStore.new(CREDENTIALS_PATH)
  storage = Google::APIClient::Storage.new(file_store)
  puts "Calling: auth = storage.authorize"
  auth = storage.authorize

  if auth.nil? || (auth.expired? && auth.refresh_token.nil?)
    puts "Loading client secrets"
    app_info = Google::APIClient::ClientSecrets.load(CLIENT_SECRETS_PATH)
    flow = Google::APIClient::InstalledAppFlow.new({
      :client_id => app_info.client_id,
      :client_secret => app_info.client_secret,
      :scope => SCOPE})
    puts "Calling: flow.authorize(storage)"
    auth = flow.authorize(storage)
    puts "Credentials saved to #{CREDENTIALS_PATH}" unless auth.nil?
  end
  auth
end

# Initialize the API
client = Google::APIClient.new(:application_name => APPLICATION_NAME)
client.authorization = authorize
