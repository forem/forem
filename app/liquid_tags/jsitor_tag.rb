class JsitorTag < LiquidTagBase
  PARTIAL = "liquids/jsitor".freeze
  URL_REGEXP = /\A(https|http):\/\/(jsitor)\.(com)\/(embed)\/([a-zA-Z0-9]+)\Z/.freeze

  def initialize(tag_name, link, token)
    super
    @link = jsitor_link_parser(link)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        link: @link,
        height: 600
      },
    )
  end

  private

  def jsitor_link_parser(link)
    parsed_link = ActionController::Base.helpers.strip_tags(link.strip)

    return parsed_link if link_valid?(parsed_link)

    jsitor_error
  end

  def link_valid?(link)
    URL_REGEXP.match link
  end

  def jsitor_error
    raise StandardError, "Invalid JSitor link. Link should have /embed/. ex: https://jsitor.com/embed/1QgJVmCam"
  end
end

Liquid::Template.register_tag("jsitor", JsitorTag)
