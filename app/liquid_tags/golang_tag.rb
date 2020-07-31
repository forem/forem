class GolangTag < LiquidTagBase
  PARTIAL = "liquids/golang".freeze

  def initialize(_tag_name, link, _parse_context)
    super
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    @embedded_url = stripped_link.split(" ").first
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        url: @embedded_url
      },
    )
  end
end

Liquid::Template.register_tag("golang", GolangTag)
