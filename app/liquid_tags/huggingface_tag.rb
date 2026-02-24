class HuggingfaceTag < LiquidTagBase
  PARTIAL = "liquids/huggingface".freeze
  HF_SPACE_REGEXP = %r{\Ahttps://[\w-]+\.hf\.space/?\z}
  HF_CO_SPACES_REGEXP = %r{\Ahttps://huggingface\.co/spaces/([\w.-]+)/([\w.-]+)/?\z}
  REGISTRY_REGEXP = %r{https://(?:[\w-]+\.hf\.space|huggingface\.co/spaces/[\w.-]+/[\w.-]+)}

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
    return stripped.chomp("/") if stripped.match?(HF_SPACE_REGEXP)

    match = stripped.match(HF_CO_SPACES_REGEXP)
    raise StandardError, I18n.t("liquid_tags.huggingface_tag.invalid_url") unless match

    "https://#{match[1]}-#{match[2]}.hf.space"
  end
end

Liquid::Template.register_tag("huggingface", HuggingfaceTag)
UnifiedEmbed.register(HuggingfaceTag, regexp: HuggingfaceTag::REGISTRY_REGEXP)
