class CloudRunTag < LiquidTagBase
  PARTIAL = "liquids/cloud_run".freeze
  REGISTRY_REGEXP = %r{\Ahttps?://[a-zA-Z0-9.-]+\.run\.app/?\z}

  def initialize(_tag_name, input, _parse_context)
    super
    args = strip_tags(input).split
    @url = parse_url(args[0].to_s)
    @ratio = parse_ratio(args[1])
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @url,
        ratio: @ratio
      },
    )
  end

  private

  def parse_url(url)
    stripped_url = url.strip
    raise StandardError, I18n.t("liquid_tags.cloud_run_tag.invalid_cloud_run_url") unless valid_url?(stripped_url)
    
    stripped_url
  end

  def valid_url?(url)
    url.match?(REGISTRY_REGEXP)
  end

  def parse_ratio(ratio)
    case ratio&.downcase
    when "landscape"
      "landscape"
    when "portrait"
      "portrait"
    else
      "default"
    end
  end
end

Liquid::Template.register_tag("cloudrun", CloudRunTag)

UnifiedEmbed.register(CloudRunTag, regexp: CloudRunTag::REGISTRY_REGEXP)
