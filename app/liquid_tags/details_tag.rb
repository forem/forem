class DetailsTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/details".freeze

  # Extend the base scrubber allowlist with the block-level elements that nested
  # liquid embeds (e.g. {% embed %}, {% comment %}, {% youtube %}) produce. Without
  # div/iframe the sanitizer strips the structural HTML and the embed renders broken.
  # Mirrors the sibling ColTag pattern (+ class/loading) and adds the iframe-specific
  # attribute embeds rely on. `style` is intentionally excluded to avoid a CSS/XSS
  # surface, matching Forem's own FEED embed allowlist.
  ALLOWED_TAGS = (MarkdownProcessor::AllowedTags::RENDERED_MARKDOWN_SCRUBBER + %w[div iframe]).freeze
  ALLOWED_ATTRIBUTES = (MarkdownProcessor::AllowedAttributes::RENDERED_MARKDOWN_SCRUBBER +
                        %w[class loading allowfullscreen]).freeze

  def initialize(_tag_name, summary, _parse_context)
    super
    @summary = sanitize(summary.strip)
  end

  def render(_context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = sanitize(
      content.xpath("//html/body").inner_html,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES,
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
