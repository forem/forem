desc "This task is called by the Heroku scheduler add-on"

task fetch_all_rss: :environment do
  Rails.application.eager_load!

  RssReader.get_all_articles(force: false) # don't force fetch. Fetch "random" subset instead of all of them.
end

# Temporary
# @sre:mstruve This is temporary until we have an efficient way to handle this task
# in Sidekiq for our large DEV community.
task send_email_digest: :environment do
  if Time.current.wday >= 3
    EmailDigest.send_periodic_digest_email
  end
end
