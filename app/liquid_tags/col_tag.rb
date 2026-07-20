class ColTag < Liquid::Block
  include LiquidTagHelpers

  PARTIAL = "liquids/col".freeze
  VALID_SPANS = (1..4).to_a.freeze
  VALID_BACKGROUNDS = %w[default subtle].freeze
  VALID_OPTIONS = %w[span background].freeze
  OPTION_REGEXP = /\A(\w+)=(\S+)\z/

  # Extends RENDERED_MARKDOWN_SCRUBBER tags with block-level elements produced by liquid tags
  ALLOWED_TAGS = (MarkdownProcessor::AllowedTags::RENDERED_MARKDOWN_SCRUBBER + %w[div footer]).freeze
  ALLOWED_ATTRIBUTES = (MarkdownProcessor::AllowedAttributes::RENDERED_MARKDOWN_SCRUBBER + %w[class loading]).freeze

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_col_options(markup.strip)
    @span = parse_span(options["span"])
    @background = parse_background(options["background"])
  end

  def render(context)
    content = super
    parsed_content = render_nested_markdown(
      content,
      allowed_tags: ALLOWED_TAGS,
      allowed_attributes: ALLOWED_ATTRIBUTES,
    )
    ApplicationController.render(
      partial: PARTIAL,
      locals: { content: parsed_content, span: @span, background: @background },
    )
  end

  private

  def parse_col_options(markup)
    return {} if markup.blank?

    markup.split.each_with_object({}) do |token, options|
      match = token.match(OPTION_REGEXP)
      option = match&.[](1)
      if match.nil? || VALID_OPTIONS.exclude?(option) || options.key?(option)
        raise StandardError, I18n.t("liquid_tags.col_tag.invalid_option", option: token)
      end

      options[option] = match[2]
    end
  end

  def parse_span(value)
    return 1 unless value

    span = value.to_i
    valid_integer = value.match?(/\A\d+\z/)
    raise StandardError, I18n.t("liquid_tags.col_tag.invalid_span") unless valid_integer && VALID_SPANS.include?(span)

    span
  end

  def parse_background(value)
    return unless value

    unless VALID_BACKGROUNDS.include?(value)
      raise StandardError, I18n.t("liquid_tags.col_tag.invalid_background")
    end

    value
  end
end

Liquid::Template.register_tag("col", ColTag)
