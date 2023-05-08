class CtaTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/cta".freeze
  STYLE_OPTIONS = %w[branded].freeze
  WIDTH_OPTIONS = %w[inline block].freeze

  def initialize(_tag_name, options, _parse_context)
    super

    options = strip_tags(options.strip).split

    @link = link(options)
    @style = style(options)
    @width = width(options)
  end

  def render(_context)
    description = Nokogiri::HTML.parse(super).at("body").text.strip
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        description: description,
        style: @style,
        width: @width
      },
    )
  end

  private

  def link(options)
    options[0]
  end

  def style(options)
    styles = options & STYLE_OPTIONS
    styles.length.positive? ? styles.first : STYLE_OPTIONS.first
  end

  def width(options)
    widths = options & WIDTH_OPTIONS
    widths.length.positive? ? widths.first : WIDTH_OPTIONS.first
  end
end

Liquid::Template.register_tag("cta", CtaTag)
