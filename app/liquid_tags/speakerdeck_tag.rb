class SpeakerdeckTag < LiquidTagBase
  PARTIAL = "liquids/speakerdeck".freeze
  REGISTRY_REGEXP = %r{https://speakerdeck.com/player/(?<id>\w{,32})}
  VALID_ID_REGEXP = /\A(?<id>\w{,32})\Z/
  REGEXP_OPTIONS  = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input = strip_tags(input)
    @id            = parse_input(stripped_input)
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

  def parse_input(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.speakerdeck_tag.invalid_speakerdeck_id") unless match

    match[:id]
  end
end

Liquid::Template.register_tag("speakerdeck", SpeakerdeckTag)

UnifiedEmbed.register(SpeakerdeckTag, regexp: SpeakerdeckTag::REGISTRY_REGEXP)
