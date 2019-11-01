class JsitorTag < LiquidTagBase
  PARTIAL = "liquids/jsitor".freeze

  def initialize(tag_name, link_id, token)
    super
    @link = jsitor_link(link_id.strip)
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

  def jsitor_link(id)
    "https://jsitor.com/embed/#{id}"
  end
end

Liquid::Template.register_tag("jsitor", JsitorTag)
