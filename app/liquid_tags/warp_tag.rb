class WarpTag < LiquidTagBase
  PARTIAL = "liquids/warp".freeze
  BLOCK_ID_PATTERN = "[a-zA-Z0-9]+".freeze
  REGISTRY_REGEXP = %r{\Ahttps://app\.warp\.dev/block/(?:embed/)?#{BLOCK_ID_PATTERN}/?\z}
  VALID_URL_REGEXP = %r{\Ahttps://app\.warp\.dev/block/(?:embed/)?(#{BLOCK_ID_PATTERN})/?\z}

  def initialize(_tag_name, input, _parse_context)
    super
    @embed_url = parse_input(strip_tags(input))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { embed_url: @embed_url },
    )
  end

  private

  def parse_input(input)
    stripped = input.strip
    match = stripped.match(VALID_URL_REGEXP)
    raise StandardError, I18n.t("liquid_tags.warp_tag.invalid_url", default: "Invalid Warp URL") unless match

    "https://app.warp.dev/block/embed/#{match[1]}"
  end
end

UnifiedEmbed.register(WarpTag, regexp: WarpTag::REGISTRY_REGEXP)
