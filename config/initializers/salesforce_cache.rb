# We clear the cache at startup so restarting the server
# is an easy way to force an immediate update.
begin
  SalesforceCache.all.each do |item|
    item.destroy!
  end

  # and warm it back up with fresh stuff so users don't have to wait
  sf = BeyondZ::Salesforce.new
  sf.update_email_caches

  CampaignMapping.all.each do |cm|
    sf.load_cached_campaign(cm.campaign_id)
  end

rescue
  # failure is acceptable, this is non-essential
  # (it may throw in the event of a nonexistent cache - which is fine, since we want it cleared anyway and nonexistent is the same in practice!)
end
