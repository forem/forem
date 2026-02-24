class ClaudebinTag < LiquidTagBase
  PARTIAL = "liquids/claudebin".freeze
  THREAD_ID_PATTERN = "[a-zA-Z0-9]+"
  REGISTRY_REGEXP = %r{\Ahttps://claudebin\.com/threads/#{THREAD_ID_PATTERN}/?\z}
  VALID_URL_REGEXP = %r{\Ahttps://claudebin\.com/threads/(#{THREAD_ID_PATTERN})/?\z}

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
    match = stripped.match(VALID_URL_REGEXP)
    raise StandardError, I18n.t("liquid_tags.claudebin_tag.invalid_url", default: "Invalid Claudebin URL") unless match

    "https://claudebin.com/threads/#{match[1]}"
  end
end

Liquid::Template.register_tag("claudebin", ClaudebinTag)
UnifiedEmbed.register(ClaudebinTag, regexp: ClaudebinTag::REGISTRY_REGEXP)
