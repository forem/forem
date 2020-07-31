class GolangTag < LiquidTagBase
  PARTIAL = "liquids/golang".freeze
  URL_REGEXP = %r{(http|https)://play.golang.com/p/[a-zA-Z0-9\-/]*}.freeze

  def initialize(_tag_name, link, _parse_context)
    super
    @link = parse_link(link)
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

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    raise_error unless valid_link?(the_link)
    the_link
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    (link_no_space =~ URL_REGEXP)&.zero?
  end

  def raise_error
    raise StandardError, "Invalid Golang Playground URL"
  end
end

Liquid::Template.register_tag("golang", GolangTag)
