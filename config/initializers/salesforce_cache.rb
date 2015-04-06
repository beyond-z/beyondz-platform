# We clear the cache at startup so restarting the server
# is an easy way to force an immediate update.
begin
  SalesforceCache.all.each do |item|
    item.destroy!
  end
rescue
  # failure is acceptable, this is non-essential
  # (it may throw in the event of a nonexistent cache - which is fine, since we want it cleared anyway and nonexistent is the same in practice!)
end
