class RedditJsonFromUrlService
  include ActionView::Helpers::SanitizeHelper

  URL_REGEXP = /\Ahttps\:\/\/(www.)?reddit.com/.freeze

  def initialize(url)
    @url = ActionController::Base.helpers.strip_tags(url).strip
  end

  def parse
    validate_url

    # Requests to Reddit require a custom `User-Agent` header to prevent 429 errors
    json = HTTParty.get("#{@url}.json", headers: { "User-Agent" => "#{ApplicationConfig['COMMUNITY_NAME']} (#{URL.url})" })

    # The JSON response is an array with two items.
    # The first one is the post itself, the second one are the comments
    data = json.first["data"]["children"][0]["data"]

    {
      author: data["author"],
      title: data["title"],
      post_url: @url,
      created_at: Time.zone.at(data["created_utc"]).strftime("%b %e '%y"),
      post_hint: data["post_hint"],
      image_url: data["url"],
      thumbnail: data["thumbnail"],
      selftext: parse_markdown_content(data["selftext"]),
      selftext_html: data["selftext_html"]
    }
  end

  private

  def parse_markdown_content(content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTMLRouge, REDCARPET_CONFIG)
    text = markdown.render(content)

    truncated = HTML_Truncator.truncate(text, 60)
    sanitize(truncated)
  end

  def validate_url
    return true if valid_url?(@url.delete(" ")) && (@url =~ URL_REGEXP)&.zero?

    raise StandardError, "Invalid Reddit link: #{@url}"
  end

  def valid_url?(url)
    url = URI.parse(url)
    url.is_a?(URI::HTTP)
  end
end
