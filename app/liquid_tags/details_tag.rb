class DetailsTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/details".freeze

  # Keeps all of RenderedMarkdownScrubber's defense-in-depth sanitization (safe
  # table-cell text-align re-application, stripping Liquid tag syntax from
  # attribute values, codeblock handling) and only extends its allowlist with the
  # block-level elements that nested liquid embeds (e.g. {% embed %}, {% comment %},
  # {% youtube %}) produce. Without div/iframe the sanitizer strips the structural
  # HTML and the embed renders broken. Mirrors the sibling ColTag pattern
  # (+ class/loading) and adds the iframe-specific attribute embeds rely on.
  # `style` is intentionally excluded to avoid a CSS/XSS surface, matching Forem's
  # own FEED embed allowlist.
  class EmbedFriendlyScrubber < RenderedMarkdownScrubber
    ADDITIONAL_TAGS = %w[div iframe].freeze
    ADDITIONAL_ATTRIBUTES = %w[class loading allowfullscreen].freeze

    def initialize
      super
      self.tags = MarkdownProcessor::AllowedTags::RENDERED_MARKDOWN_SCRUBBER + ADDITIONAL_TAGS
      self.attributes = MarkdownProcessor::AllowedAttributes::RENDERED_MARKDOWN_SCRUBBER + ADDITIONAL_ATTRIBUTES
    end
  end

  def initialize(_tag_name, summary, _parse_context)
    super
    @summary = sanitize(summary.strip)
  end

  def render(_context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = sanitize(
      content.xpath("//html/body").inner_html,
      scrubber: EmbedFriendlyScrubber.new,
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
