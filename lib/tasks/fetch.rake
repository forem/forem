desc "This task is called by the Heroku scheduler add-on"

task fetch_all_rss: :environment do
  Rails.application.eager_load!

  RssReader.get_all_articles(force: false) # don't force fetch. Fetch "random" subset instead of all of them.
end
