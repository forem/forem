class SteamTag < LiquidTagBase
  PARTIAL = "liquids/Steam".freeze
  REGISTRY_REGEXP = %r{https?://store\.steampowered\.com/app/(?<id>\d+)}

  def initialize(_tag_name, id, _parse_context)
    super
    @id = parse_id(id)
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

  def parse_id(input)
    sanitized_input = input.strip
    match_data = sanitized_input.match(REGISTRY_REGEXP)
    match_data ? match_data["id"] : validate(sanitized_input)
  end


end

Liquid::Template.register_tag("Steam", SteamTag)

UnifiedEmbed.register(SteamTag, regexp: SteamTag::REGISTRY_REGEXP)
