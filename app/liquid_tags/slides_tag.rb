class SlidesTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/slides".freeze
  OPTION_REGEXP = /(\w+)=(?:"([^"]+)"|(\S+))/
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
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: { content: content, mode: @mode },
    )
  end

  private

  def parse_options(markup)
    cleaned = strip_tags(markup)
    options = {}
    cleaned.scan(OPTION_REGEXP) do |key, quoted_val, plain_val|
      options[key] = (quoted_val || plain_val).strip
    end
    options
  end
end

Liquid::Template.register_tag("slides", SlidesTag)
