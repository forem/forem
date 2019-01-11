require "nokogiri"
require "httparty"
require "securerandom"

class RssReader
  def self.get_all_articles
    new.get_all_articles
  end

  def initialize(request_id = nil)
    @request_id = request_id
  end

  def get_all_articles
    User.where.not(feed_url: [nil, ""]).find_each do |user|
      create_articles_for_user(user)
    end
  end

  def fetch_user(user)
    Thread.current[:request_id] = @request_id
    Thread.current[:span_id] = @request_id
    create_articles_for_user(user)
  end

  def valid_feed_url?(link)
    true if fetch_rss(link)
  rescue StandardError
    false
  end

  private

  def create_articles_for_user(user)
    with_span("create_articles_for_user", user_id: user.id, username: user.username) do |metadata|
      feed = fetch_rss(user.feed_url.strip)
      metadata[:feed_length] = feed.entries.length if feed&.entries
      feed.entries.reverse_each do |item|
        make_from_rss_item(item, user, feed)
      rescue StandardError => e
        log_error("RssReaderError: occurred while creating article for",
                    user: user.username,
                    feed_url: user.feed_url,
                    item_count: get_item_count_error(feed),
                    error: e)
      end
    rescue StandardError => e
      log_error("RssReaderError: occurred while fetch feed for",
                  user: user.username,
                  feed_url: user.feed_url,
                  item_count: get_item_count_error(feed),
                  error: e)
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
    with_span("make_from_rss_item",
                item_id: item.entry_id,
                item_title: item.title,
                item_summary_size: item.summary&.size) do |metadata|
      return if medium_reply?(item) || article_exist?(user, item)

      article_params = {
        feed_source_url: feed_source_url = item.url.strip.split("?source=")[0],
        user_id: user.id,
        published_at: item.published,
        published_from_feed: true,
        show_comments: true,
        # body_markdown: assemble_body_markdown(item, user, feed, feed_source_url),
        body_markdown: RssReader::Assembler.call(item, user, feed, feed_source_url),
        organization_id: user.organization_id.present? ? user.organization_id : nil
      }
      article = with_timer("save_article", metadata) do
        Article.create!(article_params)
      end
      return unless Rails.env.production?

      SlackBot.delay.ping(
        "New Article Retrieved via RSS: #{article.title}\nhttps://dev.to#{article.path}",
        channel: "activity",
        username: "article_bot",
        icon_emoji: ":robot_face:",
      )
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
    title = item.title.gsub("…", "")
    content.include?(title)
  end

  def article_exist?(user, item)
    user.articles.find_by_title(item.title.strip.gsub('"', '\"'))
  end

  def log_error(error_msg, metadata)
    logger = Logger.new(STDOUT)
    parts = metadata.map { |k, v| [k.upcase.to_s.sub(/_/, "-"), v].join(": ") }
    parts = parts.unshift(error_msg)
    logger.info(parts.join(" "))

    ev = $libhoney.event
    ev.add(metadata)
    ev.add_field("error_msg", error_msg)
    ev.add_field("trace.trace_id", @request_id)
    parent_id = Thread.current[:span_id] || @request_id
    ev.add_field("trace.parent_id", parent_id)
    ev.add_field("trace.span_id", SecureRandom.uuid)
    ev.send
  end

  # This wrapper takes a span name, some optional metadata, and a block; then
  # emits a "span" to Honeycomb as part of the trace begun in the RequestTracer
  # middleware.
  #
  # The special sauce in this method is the definition / resetting of thread
  # local variables in order to correctly propagate "parent" identifiers down
  # into the block.
  def with_span(name, metadata = nil)
    trace_id = Thread.current[:request_id]
    return yield({}) unless trace_id

    id = SecureRandom.uuid
    start = Time.new
    data = {
      name: name,
      "trace.span_id": id,
      "trace.trace_id": trace_id,
      service_name: "rss_reader"
    }
    # Capture the calling scope's span ID, then restore it at the end of the
    # method.
    parent_id = Thread.current[:span_id]
    if parent_id
      data["trace.parent_id"] = parent_id
    end

    # Set the current span ID before invoking the provided block, then capture
    # the return value to return after emitting the Honeycomb event.
    Thread.current[:span_id] = id
    ret = yield data

    data[:duration_ms] = (Time.new - start) * 1000
    if metadata
      data.merge!(metadata)
    end

    ev = $libhoney.event
    ev.timestamp = start
    ev.add(data)
    ev.send

    ret
  ensure
    Thread.current[:span_id] = parent_id
  end

  def with_timer(name, data)
    start = Time.new
    ret = yield
    data[name + "_dur_ms"] = (Time.new - start) * 1000 if data

    ret
  end
end
