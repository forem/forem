class GolangTag < LiquidTagBase
  PARTIAL = "liquids/golang".freeze
  URL_REGEXP = %r{\Ahttps?://play.golang.org/p/[a-zA-Z0-9\-/]+\z}.freeze

  def initialize(_tag_name, link, _parse_context)
    super
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    raise "Invalid URL" valid_link?(the_link)
    @embedded_url = the_link
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        url: @embedded_url
      },
    )
  end

  private

  def valid_link?(link)
    link_no_space = link.delete(" ")
    link_no_space.match?(URL_REGEXP)
  end
end

Liquid::Template.register_tag("golang", GolangTag)
