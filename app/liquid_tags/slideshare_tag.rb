class SlideshareTag < LiquidTagBase
  PARTIAL = "liquids/slideshare".freeze
  REGISTRY_REGEXP = %r{https://(?:www\.)?slideshare\.net/slideshow/embed_code/key/(?<id>\w{12,14})}
  VALID_ID_REGEXP = /\A(?<id>\w{12,14})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input = strip_tags(input)
    @key = parse_input(stripped_input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        key: @key,
        height: 487
      },
    )
  end

  private

  def parse_input(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.slideshare_tag.invalid_slideshare_key") unless match

    match[:id]
  end
end

Liquid::Template.register_tag("slideshare", SlideshareTag)

UnifiedEmbed.register(SlideshareTag, regexp: SlideshareTag::REGISTRY_REGEXP)
