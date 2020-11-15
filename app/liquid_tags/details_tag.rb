class DetailsTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/details".freeze

  SANITIZATION_ALLOWED_TAGS = %w[strong em b i p code pre tt samp kbd var sub sup dfn cite big
                                 small address hr br div span h1 h2 h3 h4 h5 h6 ul ol li dl dt
                                 dd abbr acronym a img blockquote del ins iframe].freeze
  SANITIZATION_ALLOWED_ATTRIBUTES = %w[href src width height alt cite datetime title class name
                                       xml:lang abbr allowfullscreen loading].freeze

  def initialize(_tag_name, summary, _parse_context)
    super
    @summary = sanitize(summary.strip)
  end

  def render(_context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = sanitize(content.xpath("//html/body").inner_html, tags: SANITIZATION_ALLOWED_TAGS,
                                                                       attributes: SANITIZATION_ALLOWED_ATTRIBUTES)

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        summary: @summary,
        parsed_content: parsed_content
      },
    )
  end
end

Liquid::Template.register_tag("collapsible", DetailsTag)
Liquid::Template.register_tag("details", DetailsTag)
Liquid::Template.register_tag("spoiler", DetailsTag)
