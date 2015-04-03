# We clear the cache at startup so restarting the server
# is an easy way to force an immediate update.
SalesforceCache.all.each do |item|
  item.destroy!
end
