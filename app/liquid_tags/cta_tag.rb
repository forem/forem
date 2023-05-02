class CtaTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/cta".freeze

  def initialize(_tag_name, link, _parse_context)
    super
    @link = sanitize(link.strip)
  end

  def render(_context)
    description = Nokogiri::HTML.parse(super).at("body").text.strip

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        description: description
      },
    )
  end
end

Liquid::Template.register_tag("cta", CtaTag)
