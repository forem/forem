class RedditTag < LiquidTagBase
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/reddit".freeze
  REGISTRY_REGEXP = %r{\Ahttps://(www\.)?reddit\.com}

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
    json = HTTParty.get("#{@url}.json",
                        headers: { "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" })

    # The JSON response is an array with two items.
    # The first one is the post itself, the second one are the comments
    data = json.first["data"]["children"][0]["data"]

    {
      author: data["author"],
      title: data["title"],
      post_url: @url,
      created_at: I18n.l(Time.zone.at(data["created_utc"]), format: :reddit),
      post_hint: data["post_hint"],
      image_url: data["url"],
      thumbnail: data["thumbnail"],
      selftext: parse_markdown_content(data["selftext"]),
      selftext_html: data["selftext_html"]
    }
  end

  def parse_markdown_content(content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTMLRouge, Constants::Redcarpet::CONFIG)
    text = markdown.render(content)

    sanitize(HTML_Truncator.truncate(text, 60))
  end

  def validate_url
    return true if valid_url?(@url.delete(" ")) && (@url =~ REGISTRY_REGEXP)&.zero?

    raise StandardError, I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: @url)
  end

  def valid_url?(url)
    url = Addressable::URI.parse(url)
    %w[http https].include? url.scheme
  end
end

Liquid::Template.register_tag("reddit", RedditTag)

UnifiedEmbed.register(RedditTag, regexp: RedditTag::REGISTRY_REGEXP)
