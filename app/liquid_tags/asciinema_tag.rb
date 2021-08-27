class AsciinemaTag < LiquidTagBase
  PARTIAL = "liquids/asciinema".freeze
  ASCIINEMA_URL_REGEX = %r{https://asciinema.org/a/(?<id>\d+)}

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
    match_data = sanitized_input.match(ASCIINEMA_URL_REGEX)
    match_data ? match_data["id"] : validate(sanitized_input)
  end

  def validate(id)
    raise "Invalid Asciinema ID: #{id}" unless id.match?(/\A\d+\z/)

    id
  end
end

Liquid::Template.register_tag("asciinema", AsciinemaTag)
