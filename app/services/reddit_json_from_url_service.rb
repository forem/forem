# app/services/reddit_json_from_url_service.rb
class RedditJsonFromUrlService
  include ActionView::Helpers::SanitizeHelper

  def initialize(url)
    @url = ActionController::Base.helpers.strip_tags(url).strip
  end

  def parse
    # Requests to Reddit require a custom `User-Agent` header to prevent 429 errors
    json = HTTParty.get("#{@url}.json", headers: { "User-Agent" => "ThePracticalDev" })
    # The JSON response is an array with two items.
    # The first one is the post itself, the second one are the comments
    data = json.first["data"]["children"][0]["data"]

    {
      author: data["author"],
      title: data["title"],
      post_url: @url,
      created: data["created_utc"],
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
end
