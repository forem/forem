class CtaTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/cta".freeze

  def initialize(_tag_name, link, _parse_context)
    super
    @link = strip_tags(link.strip)
  end

  def render(_context)
    description = Nokogiri::HTML.parse(super).at("body").text.strip

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        description: description,
        style: "branded" # in the future we can use this property to expose different cta styles
      },
    )
  end
end

Liquid::Template.register_tag("cta", CtaTag)
