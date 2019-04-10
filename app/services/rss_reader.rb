class RssReader
  def self.get_all_articles(force = true)
    new.get_all_articles(force)
  end

  def get_all_articles(force = true)
    User.where.not(feed_url: [nil, ""]).find_each do |user|
      # unless forced, fetch sparingly
      next if force == false && (rand(2) == 1 || user.feed_fetched_at > 15.minutes.ago)

      create_articles_for_user(user)
    end
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

  attr_reader :request_id

  def create_articles_for_user(user)
    with_span("create_articles_for_user", user_id: user.id, username: user.username) do |metadata|
      user.update_column(:feed_fetched_at, Time.current)
      feed = fetch_rss(user.feed_url.strip)

      metadata[:feed_length] = feed.entries.length if feed&.entries

      feed.entries.reverse_each do |item|
        make_from_rss_item(item, user, feed)
      rescue StandardError => e
        logger.error(
          "RssReaderError: occurred while creating article",
          rss_reader_info: {
            user: user.username,
            feed_url: user.feed_url,
            item_count: get_item_count_error(feed),
            error: e
          },
        )
      end
    rescue StandardError => e
      logger.error(
        "RssReaderError: occurred while fetching feed",
        rss_reader_info: {
          user: user.username,
          feed_url: user.feed_url,
          item_count: get_item_count_error(feed),
          error: e
        },
      )
    end
  end

  def get_item_count_error(feed)
    if feed
      feed.entries ? feed.entries.length : "no count"
    else
      "NIL FEED, INVALID URL"
    end
  end

  def fetch_rss(url)
    with_span("fetch_rss", url: url) do |metadata|
      xml = with_timer("http_get", metadata) do
        HTTParty.get(url).body
      end
      with_timer("parse_xml", metadata) do
        Feedjira::Feed.parse xml
      end
    end
  end

  def make_from_rss_item(item, user, feed)
    with_span(
      "make_from_rss_item",
      item_id: item.entry_id,
      item_title: item.title,
      item_summary_size: item.summary&.size,
    ) do |metadata|

      return if medium_reply?(item) || article_exists?(user, item)

      article = with_timer("save_article", metadata) do
        feed_source_url = item.url.strip.split("?source=")[0]
        Article.create!(
          feed_source_url: feed_source_url,
          user_id: user.id,
          published_at: item.published,
          published_from_feed: true,
          show_comments: true,
          body_markdown: RssReader::Assembler.call(item, user, feed, feed_source_url),
          organization_id: user.organization_id.presence,
        )
      end

      send_slack_notification(article)
    end
  end

  def get_host_without_www(url)
    url = "http://#{url}" if URI.parse(url).scheme.nil?
    host = URI.parse(url).host.downcase
    host.start_with?("www.") ? host[4..-1] : host
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

  def send_slack_notification(article)
    return unless Rails.env.production?

    SlackBot.delay.ping(
      "New Article Retrieved via RSS: #{article.title}\nhttps://dev.to#{article.path}",
      channel: "activity",
      username: "article_bot",
      icon_emoji: ":robot_face:",
    )
  end

  def with_timer(name, data)
    start = Time.current
    ret = yield
    data[name + "_dur_ms"] = (Time.current - start) * 1000 if data
    ret
  end
end
