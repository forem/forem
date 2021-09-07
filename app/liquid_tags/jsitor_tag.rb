class JsitorTag < LiquidTagBase
  PARTIAL = "liquids/jsitor".freeze
  URL_REGEXP = %r{\A(https|http)://jsitor\.com/embed/\w+[-?a-zA-Z&]*\Z}
  ID_REGEXP = /\A[\w&?-]+\Z/

  def initialize(_tag_name, link, _parse_context)
    super
    @link = jsitor_link_parser(link)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        height: 400
      },
    )
  end

  private

  def jsitor_link_parser(link)
    parsed_link = ActionController::Base.helpers.strip_tags(link.strip).gsub("amp;", "")
    validate_link(parsed_link)
  end

  def validate_link(link)
    return link if URL_REGEXP.match link
    return "https://jsitor.com/embed/#{link}" if ID_REGEXP.match link

    jsitor_error
  end

  def jsitor_error
    raise StandardError, "Invalid JSitor link. Please read the editor guide for more information"
  end
end

Liquid::Template.register_tag("jsitor", JsitorTag)
