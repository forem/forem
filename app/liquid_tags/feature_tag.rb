class FeatureTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/feature".freeze
  OPTION_REGEXP = /(\w+)=(?:"([^"]+)"|(\S+))/

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @icon = options["icon"]
    @title = options["title"]
    raise StandardError, I18n.t("liquid_tags.feature_tag.missing_title") unless @title
  end

  def render(context)
    content = super
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        icon: @icon,
        title: @title,
        content: content,
      },
    )
  end

  private

  def parse_options(markup)
    options = {}
    markup.scan(OPTION_REGEXP) do |key, quoted_val, plain_val|
      options[key] = quoted_val || plain_val
    end
    options
  end
end

Liquid::Template.register_tag("feature", FeatureTag)
