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
    lightning
    location
    lock
    organization
    pencil
    people
    raised-hands
    search
    sparkle-heart
    sparkles
    team
    verified
    video-camera
    wallet
  ].freeze

  # "rocket" was documented in the editor help, and "zap" is used in
  # published content; neither shipped a matching SVG
  LEGACY_ICON_ALIASES = {
    "rocket" => "lightning",
    "zap" => "lightning"
  }.freeze

  ICON_ASSET_GLOB = "app/assets/images/*.svg".freeze

  # off-list names with a root SVG rendered before ICONS existed, so they stay valid
  def self.legacy_asset_icons
    @legacy_asset_icons ||= Rails.root.glob(ICON_ASSET_GLOB).reject(&:empty?).to_set do |path|
      path.basename(".svg").to_s
    end
  end

  def self.renderable_icon?(name)
    ICONS.include?(name) || legacy_asset_icons.include?(name)
  end

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
    return icon if self.class.renderable_icon?(icon)

    raise StandardError, I18n.t(
      "liquid_tags.feature_tag.invalid_icon",
      icon: icon,
      valid_icons: ICONS.join(", "),
    )
  end
end

Liquid::Template.register_tag("feature", FeatureTag)
