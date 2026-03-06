class ColTag < Liquid::Block
  PARTIAL = "liquids/col".freeze
  VALID_SPANS = (1..4).to_a.freeze
  OPTION_REGEXP = /\Aspan=(\d+)\z/

  def initialize(tag_name, markup, parse_context)
    super
    @span = parse_span(markup.strip)
  end

  def render(context)
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: { content: content, span: @span },
    )
  end

  private

  def parse_span(markup)
    return 1 if markup.blank?

    match = markup.match(OPTION_REGEXP)
    raise StandardError, I18n.t("liquid_tags.col_tag.invalid_span") unless match

    span = match[1].to_i
    raise StandardError, I18n.t("liquid_tags.col_tag.invalid_span") unless VALID_SPANS.include?(span)

    span
  end
end

Liquid::Template.register_tag("col", ColTag)
