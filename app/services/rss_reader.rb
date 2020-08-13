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
          item_count: get_item_count_error(feed),
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
        item_count: get_item_count_error(feed),
        error_message: "RssReaderError: occurred while fetching feed"
      },
    )
    []
  end

  def get_item_count_error(feed)
    if feed
      feed.entries ? feed.entries.length : "no count"
    else
      "NIL FEED, INVALID URL"
    end
  end

  def fetch_rss(url)
    xml = HTTParty.get(url).body
    Feedjira.parse xml
  end

  def make_from_rss_item(item, user, feed)
    return if medium_reply?(item) || article_exists?(user, item)

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

  def get_host_without_www(url)
    url = "http://#{url}" if URI.parse(url).scheme.nil?
    host = URI.parse(url).host.downcase
    host.start_with?("www.") ? host[4..] : host
  end

  def medium_reply?(item)
    get_host_without_www(item.url.strip) == "medium.com" &&
      !item[:categories] &&
      content_is_not_the_title?(item)
  end

  def content_is_not_the_title?(item)
    # [[:space:]] removes all whitespace, including unicode ones.
    content = item.content.gsub(/[[:space:]]/, " ")
    title = item.title.delete("…")
    content.include?(title)
  end

  def article_exists?(user, item)
    title = item.title.strip.gsub('"', '\"')
    feed_source_url = item.url.strip.split("?source=")[0]
    relation = user.articles
    relation.where(title: title).or(relation.where(feed_source_url: feed_source_url)).exists?
  end

  def report_error(error, metadata)
    Honeybadger.context(metadata)
    Honeybadger.notify(error)
  end
end
