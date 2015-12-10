module SubmissionsHelper
  # rubocop:disable LineLength
  # An array of userInfo objects are stored in the USER_INFOS env var as a JSON string in this format:
  # '{ "brian@bebraven.org" : {"name" : "Brian Sadler", "coach" : "John Doe", "documentKey" : "0AhkyYmQz77njdHpMeXRpNFUtZHViaWxQMWpfVkpuZmc" }, ... }'
  $userInfos = JSON.parse(File.read(::Rails.root.join('config', 'userInfo.json')))
  # rubocop:enable LineLength
end
