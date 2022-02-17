class AsciinemaTag < LiquidTagBase
  PARTIAL = "liquids/asciinema".freeze
  REGISTRY_REGEXP = %r{https://asciinema\.org/a/(?<id>\d+)}

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

  def validate(id)
    raise I18n.t("liquid_tags.asciinema_tag.invalid_asciinema_id", id: id) unless id.match?(/\A\d+\z/)

    id
  end
end

Liquid::Template.register_tag("asciinema", AsciinemaTag)

UnifiedEmbed.register(AsciinemaTag, regexp: AsciinemaTag::REGISTRY_REGEXP)
