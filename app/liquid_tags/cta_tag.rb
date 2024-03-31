class CtaTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/cta".freeze
  # at some point we may want to pass in options to dictate which type of CTA the user wants to use,
  # i.e. secondary, primary, branded. This sets the scene for it without actually providing that option now.
  TYPE_OPTIONS = %w[branded].freeze
  DESCRIPTION_LENGTH = 128

  def initialize(_tag_name, options, _parse_context)
    super
    @link = strip_tags(options.strip)
  end

  def render(_context)
    content = Nokogiri::HTML.parse(super)

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        description: sanitized_description(content),
        type: TYPE_OPTIONS.first
      },
    )
  end

  private

  def sanitized_description(content)
    stripped_description = strip_tags(content.xpath("//html/body").inner_html).delete("\n").strip
    stripped_description.truncate(DESCRIPTION_LENGTH)
  end
end

Liquid::Template.register_tag("cta", CtaTag)
