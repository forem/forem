class NetlifyTag < LiquidTagBase
  PARTIAL = "liquids/netlify".freeze
  REGISTRY_REGEXP = %r{https://(?<subdomain>[\w-]+)\.netlify\.app(?<path>/\S*)?}
  VALID_URL_REGEXP = %r{\Ahttps://[\w-]+\.netlify\.app(/\S*)?\z}

  def initialize(_tag_name, input, _parse_context)
    super
    stripped_input = fully_unescape_html(strip_tags(input))
    @url = parse_url(stripped_input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { url: @url },
    )
  end

  private

  def fully_unescape_html(str)
    prev = nil
    while str != prev
      prev = str
      str = CGI.unescape_html(str)
    end
    str
  end

  def parse_url(input)
    url = input.strip.split.first
    raise StandardError, I18n.t("liquid_tags.netlify_tag.invalid_url") unless url&.match?(VALID_URL_REGEXP)

    url
  end
end

Liquid::Template.register_tag("netlify", NetlifyTag)

UnifiedEmbed.register(NetlifyTag, regexp: NetlifyTag::REGISTRY_REGEXP)
