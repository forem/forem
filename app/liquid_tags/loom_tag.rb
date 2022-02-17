class LoomTag < LiquidTagBase
  PARTIAL = "liquids/loom".freeze
  REGISTRY_REGEXP = %r{https://(www\.)?loom\.com/(share|embed)/\w+}

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input = CGI.unescape_html(strip_tags(input))
    @url           = check_input(stripped_input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @url
      },
    )
  end

  def check_input(input)
    raise StandardError, I18n.t("liquid_tags.loom_tag.invalid_loom_url") unless input.match?(REGISTRY_REGEXP)

    input
  end
end

UnifiedEmbed.register(LoomTag, regexp: LoomTag::REGISTRY_REGEXP)
