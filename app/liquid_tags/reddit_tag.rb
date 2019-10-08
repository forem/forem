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
        content: @reddit_content,
        url: @reddit_content[:url],
        thumbnail: @reddit_content[:thumbnail],
        author: @reddit_content[:author],
        title: @reddit_content[:title]
      },
    )
  end
end

Liquid::Template.register_tag("reddit", RedditTag)
