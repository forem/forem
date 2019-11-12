class JsitorTag < LiquidTagBase
  PARTIAL = "liquids/jsitor".freeze
  URL_REGEXP = /\A(https|http):\/\/(jsitor)\.(com)\/(embed)\/([a-zA-Z0-9]+)([?a-zA-Z&]*)\Z/.freeze
  ID_REGEXP = /\A([?a-zA-Z0-9&])*\Z/.freeze

  def initialize(tag_name, link, token)
    super
    @link = jsitor_link_parser(link)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
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
    link_valid?(parsed_link)
  end

  def link_valid?(link)
    return link if URL_REGEXP.match link
    return "https://jsitor.com/embed/#{link}" if ID_REGEXP.match link

    jsitor_error
  end

  def jsitor_error
    raise StandardError, "Invalid JSitor link. Link should have /embed/.
    ex: https://jsitor.com/embed/B7FQ5tHbY or with ID B7FQ5tHbY.
    Parameters are optional.
    Please read guide for more information"
  end
end

Liquid::Template.register_tag("jsitor", JsitorTag)
