desc "This task is called by the Heroku scheduler add-on"

task fetch_all_rss: :environment do
  if FeatureFlag.enabled?(:feeds_import)
    Feeds::Import.call(earlier_than: 4.hours.ago)
  else
    # don't force fetch. Fetch "random" subset instead of all of them.
    RssReader.get_all_articles(force: false)
  end
end

task fetch_feeds_import: :environment do
  Feeds::Import.call(earlier_than: 4.hours.ago)
end

# Temporary
# @sre:mstruve This is temporary until we have an efficient way to handle this task
# in Sidekiq for our large DEV community.
task send_email_digest: :environment do
  if Time.current.wday >= 3
    EmailDigest.send_periodic_digest_email
  end
end
