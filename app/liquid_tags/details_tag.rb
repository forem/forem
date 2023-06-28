class DetailsTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/details".freeze

  def initialize(_tag_name, summary, _parse_context)
    super
    @summary = sanitize(summary.strip)
  end

  def render(_context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = sanitize(
      content.xpath("//html/body").inner_html,
      tags: MarkdownProcessor::AllowedTags::RENDERED_MARKDOWN_SCRUBBER,
      attributes: MarkdownProcessor::AllowedAttributes::RENDERED_MARKDOWN_SCRUBBER,
    )

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
