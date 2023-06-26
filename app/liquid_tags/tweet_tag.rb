class TweetTag < LiquidTagBase
  PARTIAL = "liquids/tweet".freeze
  REGISTRY_REGEXP = %r{https://twitter\.com/\w{1,15}/status/(?<id>\d{10,20})}
  VALID_ID_REGEXP = /\A(?<id>\d{10,20})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  def initialize(_tag_name, id, _parse_context)
    super
    input = CGI.unescape_html(strip_tags(id))
    @id = parse_id_or_url(input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
      },
    )
  end

  private

  def parse_id_or_url(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.tweet_tag.invalid_twitter_id") unless match

    match[:id]
  end
end

Liquid::Template.register_tag("tweet", TweetTag)
Liquid::Template.register_tag("twitter", TweetTag)
UnifiedEmbed.register(TweetTag, regexp: TweetTag::REGISTRY_REGEXP)
