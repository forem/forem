class TrecsTag < LiquidTagBase
  PARTIAL = "liquids/trecs".freeze
  ID_REGEXP = /[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}/i
  REGISTRY_REGEXP = %r{https://trecs\.run/watch/(?<id>#{ID_REGEXP.source})(?:\?t=(?<start>\d+))?}i

  def initialize(_tag_name, input, _parse_context)
    super
    @id, @start = parse_input(input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        start: @start
      },
    )
  end

  private

  def parse_input(input)
    stripped_input = strip_tags(input)

    match_data = stripped_input.match(REGISTRY_REGEXP)
    return [match_data[:id], match_data[:start]] if match_data
    return [stripped_input, nil] if stripped_input.match?(/\A#{ID_REGEXP.source}\z/i)

    raise StandardError, I18n.t("liquid_tags.trecs_tag.invalid_trecs_id", id: stripped_input)
  end
end

Liquid::Template.register_tag("trecs", TrecsTag)

UnifiedEmbed.register(TrecsTag, regexp: TrecsTag::REGISTRY_REGEXP)
