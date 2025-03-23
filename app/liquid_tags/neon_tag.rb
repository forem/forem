class NeonTag < LiquidTagBase
  PARTIAL = "liquids/neon".freeze
  # rubocop:disable Layout/LineLength
  def initialize(_tag_name, id, _parse_context)
    super
    input   = CGI.unescape_html(strip_tags(id))
    @path   = parse_id_or_url(input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        path: @path
      },
    )
  end

  private

  def parse_id_or_url(input)
    true
  end
end

Liquid::Template.register_tag("neon", NeonTag)
