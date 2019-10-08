# app/liquid_tags/reddit_tag.rb
class RedditTag < LiquidTagBase
  PARTIAL = "liquids/reddit".freeze

  def initialize(_tag_name, url, _tokens)
    @url = url
    @reddit_content = RedditJsonFromUrlService.new(@url).parse
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        author: @reddit_content[:author],
        title: @reddit_content[:title],
        post_url: @reddit_content[:post_url],
        created_at: @reddit_content[:created_utc],
        post_hint: @reddit_content[:post_hint],
        image_url: @reddit_content[:image_url],
        thumbnail: @reddit_content[:thumbnail],
        html_text: @reddit_content[:selftext_html],
        markdown_text: @reddit_content[:selftext]
      },
    )
  end
end

Liquid::Template.register_tag("reddit", RedditTag)
