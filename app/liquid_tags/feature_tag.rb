class FeatureTag < Liquid::Block
  include ActionView::Helpers::SanitizeHelper
  include LiquidTagHelpers

  PARTIAL = "liquids/feature".freeze
  ICON_NAME_REGEXP = /\A[a-z0-9-]+\z/

  ICONS = %w[
    analytics
    badge
    book
    boost
    calendar
    checkmark
    code
    cog
    comment
    connect
    discover
    email
    fire
    heart
    image
    lightbulb
    lightning
    location
    lock
    organization
    pencil
    people
    raised-hands
    search
    sparkle-heart
    team
    verified
    video-camera
    wallet
  ].freeze

  # "rocket" was documented in the editor help but never shipped an asset
  LEGACY_ICON_ALIASES = { "rocket" => "lightning" }.freeze

  def initialize(tag_name, markup, parse_context)
    super
    options = parse_options(markup.strip)
    @title = options["title"]
    raise StandardError, I18n.t("liquid_tags.feature_tag.missing_title") unless @title

    @icon = validate_icon(options["icon"])
  end

  def render(context)
    content = super
    parsed_content = render_nested_markdown(content)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        icon: @icon,
        title: @title,
        content: parsed_content,
      },
    )
  end

  private

  def validate_icon(icon)
    return icon if icon.blank? || !icon.match?(ICON_NAME_REGEXP)
    return LEGACY_ICON_ALIASES[icon] if LEGACY_ICON_ALIASES.key?(icon)
    return icon if ICONS.include?(icon)

    raise StandardError, I18n.t(
      "liquid_tags.feature_tag.invalid_icon",
      icon: icon,
      valid_icons: ICONS.join(", "),
    )
  end
end

Liquid::Template.register_tag("feature", FeatureTag)
