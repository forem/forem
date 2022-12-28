class FacebookTag < LiquidTagBase
  PARTIAL = "liquids/facebook".freeze
  # rubocop:disable Layout/LineLength
  REGISTRY_REGEXP = %r{https?://(?:www\.|m\.|)?(?:facebook\.com)/([a-zA-Z]+)/(posts|videos|)(.*)?}
  # rubocop:enable Layout/LineLength
  REGEXP_OPTIONS = [REGISTRY_REGEXP].freeze

  def initialize(_tag_name, id, _parse_context)
    super

    input   = CGI.unescape_html(strip_tags(id))
    match = input.match(REGISTRY_REGEXP)
    p 'match.match'
    p match
    @id     = parse_id_or_url(input)
    @type   = ((match[2] == 'videos' || match[1] == 'watch') ? 'video' : 'post');
    @width  = '100%'
    @height = 738
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        type: @type,
        width: @width,
        height: @height
      },
    )
  end

  private

  def parse_id_or_url(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.facebook_tag.invalid_facebook_url") unless match

    return input
  end
end

Liquid::Template.register_tag("facebook", FacebookTag)

UnifiedEmbed.register(FacebookTag, regexp: FacebookTag::REGISTRY_REGEXP)
