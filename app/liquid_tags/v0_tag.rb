class V0Tag < LiquidTagBase
  PARTIAL = "liquids/v0".freeze
  VUSERCONTENT_REGEXP = %r{\Ahttps://[\w-]+(?:\.lite)?\.vusercontent\.net(?:/[\w.-]*)*/?\z}
  V0_CHAT_REGEXP = %r{\Ahttps://v0\.dev/chat/[\w-]+/?\z}
  REGISTRY_REGEXP = %r{https://(?:[\w-]+(?:\.lite)?\.vusercontent\.net(?:/[\w.-]*)*|v0\.dev/chat/[\w-]+)}

  def initialize(_tag_name, input, _parse_context)
    super
    @url = parse_input(strip_tags(input))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { url: @url },
    )
  end

  private

  def parse_input(input)
    stripped = input.strip
    unless stripped.match?(VUSERCONTENT_REGEXP) || stripped.match?(V0_CHAT_REGEXP)
      raise StandardError, I18n.t("liquid_tags.v0_tag.invalid_url", default: "Invalid v0 URL")
    end

    stripped.chomp("/")
  end
end

UnifiedEmbed.register(V0Tag, regexp: V0Tag::REGISTRY_REGEXP)
