class CloudRunTag < LiquidTagBase
  PARTIAL = "liquids/cloud_run".freeze
  REGISTRY_REGEXP = %r{\Ahttps?://[a-zA-Z0-9.-]+\.run\.app/?\z}
  DEFAULT_LAYOUT = "default".freeze
  LAYOUT_OPTIONS = {
    DEFAULT_LAYOUT => { aspect_ratio: "4 / 3", height: "600px" },
    "landscape" => { aspect_ratio: "16 / 9", height: "420px" },
    "portrait" => { aspect_ratio: "3 / 4", height: "780px" },
  }.freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @url, @layout = parse_input(strip_tags(input))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @url,
        aspect_ratio: LAYOUT_OPTIONS.fetch(@layout)[:aspect_ratio],
        iframe_height: LAYOUT_OPTIONS.fetch(@layout)[:height],
      },
    )
  end

  private

  def parse_input(input)
    url, layout = input.strip.split(/\s+/, 2)
    raise StandardError, I18n.t("liquid_tags.cloud_run_tag.invalid_cloud_run_url") unless valid_url?(url)

    [url, parse_layout(layout)]
  end

  def parse_layout(layout)
    return DEFAULT_LAYOUT if layout.blank?

    normalized_layout = layout.downcase
    return normalized_layout if LAYOUT_OPTIONS.key?(normalized_layout)

    raise StandardError, I18n.t("liquid_tags.cloud_run_tag.invalid_aspect_ratio")
  end

  def valid_url?(url)
    url.present? && url.match?(REGISTRY_REGEXP)
  end
end

Liquid::Template.register_tag("cloudrun", CloudRunTag)

UnifiedEmbed.register(CloudRunTag, regexp: CloudRunTag::REGISTRY_REGEXP)
