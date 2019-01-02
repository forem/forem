require "rss"
require "open-uri"
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
    User.where.not(feed_url: nil).each do |u|
      feed_url = u.feed_url.strip
      next if feed_url == ""

      create_articles_for_user(u)
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
      feed = fetch_rss(user.feed_url)
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
        body_markdown: assemble_body_markdown(item, user, feed, feed_source_url),
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

  def assemble_body_markdown(item, user, feed, feed_source_url)
    with_span("assemble_body_markdown", item_title: item.title) do
      body = <<~HEREDOC
        ---
        title: #{item.title.strip}
        published: false
        tags: #{get_tags(item[:categories])}
        canonical_url: #{user.feed_mark_canonical ? feed_source_url : ''}
        ---

        #{finalize_reverse_markdown(item, feed)}

      HEREDOC
      body.strip
    end
  end

  def get_tags(categories)
    categories.first(4).map { |tag| tag[0..19] }.join(",") if categories
  end

  def get_content(item)
    item.content || item.summary || item.description
  end

  def finalize_reverse_markdown(item, feed)
    cleaned_item_content = HtmlCleaner.new.clean_html(get_content(item))
    cleaned_item_content = thorough_parsing(cleaned_item_content, feed.url)
    ReverseMarkdown.convert(cleaned_item_content, github_flavored: true).
      gsub("```\n\n```", "").gsub(/&nbsp;|\u00A0/, " ")
  end

  def thorough_parsing(content, feed_url)
    with_span("thorough_parsing", content_length: content.length) do
      html_doc = Nokogiri::HTML(content)
      find_and_replace_possible_links!(html_doc)
      if feed_url.include?("medium.com")
        parse_and_translate_gist_iframe!(html_doc)
        parse_and_translate_youtube_iframe!(html_doc)
        parse_and_translate_tweet!(html_doc)
      else
        clean_relative_path!(html_doc, feed_url)
      end
      html_doc.to_html
    end
  end

  def parse_and_translate_gist_iframe!(html_doc)
    html_doc.css("iframe").each do |iframe|
      a_tag = iframe.css("a")
      next if a_tag.empty?

      possible_link = a_tag[0].inner_html
      if /medium\.com\/media\/.+\/href/.match?(possible_link)
        real_link = ""
        open(possible_link) do |h|
          real_link = h.base_uri.to_s
        end
        return unless real_link.include?("gist.github.com")

        iframe.name = "p"
        iframe.keys.each { |attr| iframe.remove_attribute(attr) }
        iframe.inner_html = "{% gist #{real_link} %}"
      end
    end
    html_doc
  end

  def parse_and_translate_tweet!(html_doc)
    html_doc.search("style").remove
    html_doc.search("script").remove
    html_doc.css("blockquote").each do |bq|
      bq_with_p = bq.css("p")
      next if bq_with_p.empty?

      second_content = bq_with_p.css("p")[1].css("a")[0].attributes["href"].value
      if bq_with_p.length == 2 && second_content.include?("twitter.com")
        bq.name = "p"
        tweet_id = second_content.scan(/\/status\/(\d{10,})/).flatten.first
        bq.inner_html = "{% tweet #{tweet_id} %}"
      end
    end
  end

  def parse_and_translate_youtube_iframe!(html_doc)
    html_doc.css("iframe").each do |iframe|
      if /youtube\.com/.match?(iframe.attributes["src"].value)
        iframe.name = "p"
        youtube_id = iframe.attributes["src"].value.scan(/embed%2F(.{4,12})%3F/).flatten.first
        iframe.keys.each { |attr| iframe.remove_attribute(attr) }
        iframe.inner_html = "{% youtube #{youtube_id} %}"
      end
    end
  end

  def clean_relative_path!(html_doc, url)
    html_doc.css("img").each do |img_tag|
      path = img_tag.attributes["src"].value
      img_tag.attributes["src"].value = URI.join(url, path).to_s if path.start_with? "/"
    end
  end

  def find_and_replace_possible_links!(html_doc)
    html_doc.css("a").each do |a_tag|
      link = a_tag.attributes["href"]&.value
      next unless link

      found_article = Article.find_by(feed_source_url: link)&.decorate
      if found_article
        a_tag.attributes["href"].value = found_article.url
      end
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
