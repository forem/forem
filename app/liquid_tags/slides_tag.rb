class SlidesTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper
  include LiquidTagHelpers

  PARTIAL = "liquids/slides".freeze
  VALID_MODES = %w[default carousel].freeze

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @mode = options["mode"] || "default"
    unless VALID_MODES.include?(@mode)
      raise StandardError, I18n.t("liquid_tags.slides_tag.invalid_mode")
    end
  end

  def render(context)
    content = ""
    @body.nodelist.each do |node|
      content << node.render(context) if node.is_a?(SlideTag)
    end
    ApplicationController.render(
      partial: PARTIAL,
      locals: { content: content, mode: @mode },
    )
  end
end

Liquid::Template.register_tag("slides", SlidesTag)
