class CtaTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/cta".freeze
  # at some point we may want to pass in options to dictate which type of CTA the user wants to use,
  # i.e. secondary, primary, branded. This sets the scene for it without actually providing that option now.
  TYPE_OPTIONS = %w[branded].freeze

  def initialize(_tag_name, options, _parse_context)
    super
    @link = strip_tags(options.strip)
  end

  def render(_context)
    description = Nokogiri::HTML.parse(super).at("body").text.strip
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        description: description,
        type: TYPE_OPTIONS.first
      },
    )
  end
end

Liquid::Template.register_tag("cta", CtaTag)
