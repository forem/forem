class RedditTag < LiquidTagBase
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/reddit".freeze
  ALLOWED_HOSTS = %w[reddit.com www.reddit.com].freeze
  REGISTRY_REGEXP = %r{\Ahttps://(?:www\.)?reddit\.com(?:/|\z)}i
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

    # Requests to Reddit require a custom `User-Agent` header to prevent 429 errors
    response = SafeHttp.get(
      "#{@url}.json",
      timeout: HTTP_TIMEOUT_SECONDS,
      headers: { "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" },
    )

    last_host = response.try(:request)&.last_uri&.host&.downcase
    raise StandardError, invalid_reddit_link_message if last_host.present? && ALLOWED_HOSTS.exclude?(last_host)

    # The JSON response is an array with two items.
    # The first one is the post itself, the second one are the comments
    parsed = response.respond_to?(:parsed_response) ? response.parsed_response : response
    data = parsed.dig(0, "data", "children", 0, "data") if parsed.is_a?(Array)
    raise StandardError, invalid_reddit_link_message unless data.is_a?(Hash) && data["created_utc"].is_a?(Numeric)

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
  rescue SafeHttp::Error, HTTParty::Error, SocketError, Timeout::Error
    raise StandardError, invalid_reddit_link_message
  end

  def parse_markdown_content(content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTMLRouge, Constants::Redcarpet::CONFIG)
    text = markdown.render(content)

    sanitize(HTML_Truncator.truncate(text, 60))
  end

  def validate_url
    return true if valid_url?(@url) && @url.match?(REGISTRY_REGEXP)

    raise StandardError, invalid_reddit_link_message
  end

  def valid_url?(url)
    return false if url.blank? || url.match?(/\s/)

    uri = URI.parse(url)
    addressable = Addressable::URI.parse(url)

    [uri, addressable].all? do |parsed|
      parsed.scheme&.downcase == "https" &&
        parsed.userinfo.blank? &&
        (parsed.port.nil? || parsed.port == 443) &&
        ALLOWED_HOSTS.include?(parsed.host&.downcase)
    end
  rescue URI::InvalidURIError, Addressable::URI::InvalidURIError
    false
  end

  def invalid_reddit_link_message
    I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: @url)
  end
end

Liquid::Template.register_tag("reddit", RedditTag)

UnifiedEmbed.register(RedditTag, regexp: RedditTag::REGISTRY_REGEXP)
