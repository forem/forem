class BlogcastTag < LiquidTagBase
  PARTIAL = "liquids/blogcast".freeze
  REGISTRY_REGEXP = %r{https?://(?:app\.)?(?:blogcast\.host/embed/)(?<video_id>\d{1,9})}
  VALID_ID_REGEXP = /\A(?<video_id>\d{1,9})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  def initialize(_tag_name, id, _parse_context)
    super
    input = strip_tags(id)
    @id   = parse_id_or_url(input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id
      },
    )
  end

  private

  def parse_id_or_url(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.blogcast_tag.invalid_blogcast_id") unless match

    match[:video_id]
  end
end

Liquid::Template.register_tag("blogcast", BlogcastTag)

UnifiedEmbed.register(BlogcastTag, regexp: BlogcastTag::REGISTRY_REGEXP)
