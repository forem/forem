class RssReader
  def self.get_all_articles(force: true)
    new.get_all_articles(force: force)
  end

  def get_all_articles(force: true)
    articles = []

    User.where.not(feed_url: [nil, ""]).find_each do |user|
      # unless forced, fetch sparingly
      next if force == false && (rand(2) == 1 || user.feed_fetched_at > 15.minutes.ago)

      user_articles = create_articles_for_user(user)
      articles.concat(user_articles) if user_articles
    end

    articles
  end

  def fetch_user(user)
    create_articles_for_user(user)
  end

  def valid_feed_url?(link)
    true if fetch_rss(link)
  rescue StandardError
    false
  end

  private

  def create_articles_for_user(user)
    user.update_column(:feed_fetched_at, Time.current)
    feed = fetch_rss(user.feed_url.strip)

    articles = []

    feed.entries.reverse_each do |item|
      article = make_from_rss_item(item, user, feed)
      articles.append(article)
    rescue StandardError => e
      report_error(
        e,
        rss_reader_info: {
          username: user.username,
          feed_url: user.feed_url,
          item_count: item_count_error(feed),
          error: "RssReaderError: occurred while creating article #{item.url}"
        },
      )
    end

    articles
  rescue StandardError => e
    report_error(
      e,
      rss_reader_info: {
        username: user.username,
        feed_url: user.feed_url,
        item_count: item_count_error(feed),
        error_message: "RssReaderError: occurred while fetching feed"
      },
    )
    []
  end

  def fetch_rss(url)
    xml = HTTParty.get(url).body
    Feedjira.parse xml
  end

  def make_from_rss_item(item, user, feed)
    return if Feeds::CheckItemMediumReply.call(item) || Feeds::CheckItemPreviouslyImported.call(item, user)

    feed_source_url = item.url.strip.split("?source=")[0]
    article = Article.create!(
      feed_source_url: feed_source_url,
      user_id: user.id,
      published_from_feed: true,
      show_comments: true,
      body_markdown: RssReader::Assembler.call(item, user, feed, feed_source_url),
      organization_id: nil,
    )

    Slack::Messengers::ArticleFetchedFeed.call(article: article)

    article
  end

  def report_error(error, metadata)
    Honeybadger.context(metadata)
    Honeybadger.notify(error)
  end

  def item_count_error(feed)
    return "NIL FEED, INVALID URL" unless feed

    feed.entries ? feed.entries.length : "no count"
  end
end
