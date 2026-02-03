class CloudRunTag < LiquidTagBase
  PARTIAL = "liquids/cloud_run".freeze
  REGISTRY_REGEXP = %r{\Ahttps?://[a-zA-Z0-9.-]+\.run\.app/?\z}

  def initialize(_tag_name, input, _parse_context)
    super
    @url = parse_input(strip_tags(input))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @url
      },
    )
  end

  private

  def parse_input(input)
    stripped_input = input.strip
    raise StandardError, I18n.t("liquid_tags.cloud_run_tag.invalid_cloud_run_url") unless valid_url?(stripped_input)
    
    stripped_input
  end

  def valid_url?(url)
    url.match?(REGISTRY_REGEXP)
  end
end

Liquid::Template.register_tag("cloudrun", CloudRunTag)

UnifiedEmbed.register(CloudRunTag, regexp: CloudRunTag::REGISTRY_REGEXP)
