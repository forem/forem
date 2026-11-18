class RedditTag < LiquidTagBase
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/reddit".freeze
  ALLOWED_HOSTS = %w[reddit.com www.reddit.com].freeze
  REGISTRY_REGEXP = %r{\Ahttps://(?:www\.)?reddit\.com(?::443)?/}i
  HTTP_TIMEOUT_SECONDS = 15

  def initialize(_tag_name, url, _parse_context)
    super
    @url = ActionController::Base.helpers.strip_tags(url).strip
    @reddit_content = parse_url
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        author: @reddit_content[:author],
        title: @reddit_content[:title],
        post_url: @reddit_content[:post_url],
        created_at: @reddit_content[:created_at],
        post_hint: @reddit_content[:post_hint],
        image_url: @reddit_content[:image_url],
        thumbnail: @reddit_content[:thumbnail],
        html_text: @reddit_content[:selftext_html],
        markdown_text: @reddit_content[:selftext]
      },
    )
  end

  private

  def parse_url
    validate_url
    request_url = json_request_url
    raise StandardError, invalid_reddit_link_message unless valid_url?(request_url)

    # Requests to Reddit require a custom `User-Agent` header to prevent 429 errors
    response = SafeHttp.get(
      request_url,
      timeout: HTTP_TIMEOUT_SECONDS,
      validate_url: method(:valid_url?),
      headers: { "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" },
    )

    parsed = response.respond_to?(:parsed_response) ? response.parsed_response : response
    data = extract_post_payload(parsed)
    raise StandardError, invalid_reddit_link_message unless data

    build_reddit_content(data)
  rescue SafeHttp::Error, HTTParty::Error, JSON::ParserError, SocketError, Timeout::Error
    raise StandardError, invalid_reddit_link_message
  end

  def json_request_url
    uri = URI.parse(@url)
    uri.path = "#{uri.path}.json" unless uri.path.end_with?(".json")
    uri.to_s
  end

  def extract_post_payload(parsed)
    # The JSON response is an array with two items.
    # The first one is the post itself, the second one are the comments
    return unless parsed.is_a?(Array) && parsed[0].is_a?(Hash)

    listing_data = parsed[0]["data"]
    children = listing_data["children"] if listing_data.is_a?(Hash)
    child_data = children[0]["data"] if children.is_a?(Array) && children[0].is_a?(Hash)
    child_data if child_data.is_a?(Hash) && child_data["created_utc"].is_a?(Numeric)
  end

  def build_reddit_content(data)
    {
      author: data["author"],
      title: data["title"],
      post_url: @url,
      created_at: I18n.l(Time.zone.at(data["created_utc"]), format: :reddit),
      post_hint: data["post_hint"],
      image_url: data["url"],
      thumbnail: data["thumbnail"],
      selftext: parse_markdown_content(data["selftext"].to_s),
      selftext_html: data["selftext_html"]
    }
  end

  def parse_markdown_content(content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTMLRouge, Constants::Redcarpet::CONFIG)
    text = markdown.render(content)

    sanitize(HTML_Truncator.truncate(text, 60))
  end

  def validate_url
    return true if valid_url?(@url)

    raise StandardError, invalid_reddit_link_message
  end

  def valid_url?(url)
    return false if url.blank? || url.match?(/\s/) || !url.match?(REGISTRY_REGEXP)

    uri = URI.parse(url)
    addressable = Addressable::URI.parse(url)

    valid_parsed_uri?(uri) && valid_parsed_uri?(addressable)
  rescue URI::InvalidURIError, Addressable::URI::InvalidURIError
    false
  end

  def valid_parsed_uri?(parsed)
    parsed.scheme&.downcase == "https" &&
      parsed.userinfo.blank? &&
      (parsed.port.nil? || parsed.port == 443) &&
      ALLOWED_HOSTS.include?(parsed.host&.downcase) &&
      parsed.path.start_with?("/")
  end

  def invalid_reddit_link_message
    I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: @url)
  end
end

Liquid::Template.register_tag("reddit", RedditTag)

UnifiedEmbed.register(RedditTag, regexp: RedditTag::REGISTRY_REGEXP)
