class DetailsTag < Liquid::Block
  PARTIAL = "liquids/details".freeze

  def initialize(_tag_name, summary, _parse_context)
    super
    @summary = summary.strip
  end

  def render(_context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text.strip

    ActionController::Base.new.render_to_string(
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
