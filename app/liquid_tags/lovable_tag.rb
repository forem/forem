class LovableTag < LiquidTagBase
  PARTIAL = "liquids/lovable".freeze
  REGISTRY_REGEXP = %r{\Ahttps://[\w-]+\.lovable\.app(?:/[\w.-]*)*/?\z}
  VALID_URL_REGEXP = %r{\Ahttps://([\w-]+\.lovable\.app(?:/[\w.-]*)*)/?\z}

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
    raise StandardError, I18n.t("liquid_tags.lovable_tag.invalid_url", default: "Invalid Lovable URL") unless match

    "https://#{match[1].chomp('/')}"
  end
end

UnifiedEmbed.register(LovableTag, regexp: LovableTag::REGISTRY_REGEXP)
