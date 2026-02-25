class HuggingfaceTag < LiquidTagBase
  PARTIAL = "liquids/huggingface".freeze
  HF_SPACE_REGEXP = %r{\Ahttps://[\w-]+\.hf\.space/?\z}
  HF_CO_SPACES_REGEXP = %r{\Ahttps://huggingface\.co/spaces/([\w.-]+)/([\w.-]+)/?\z}
  HF_CO_DATASETS_REGEXP = %r{\Ahttps://huggingface\.co/datasets/([\w.-]+)/([\w.-]+)(?:/embed/viewer)?\z}
  REGISTRY_REGEXP = %r{https://(?:[\w-]+\.hf\.space|huggingface\.co/(?:spaces|datasets)/[\w.-]+/[\w.-]+)}

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

    spaces_match = stripped.match(HF_CO_SPACES_REGEXP)
    return "https://#{spaces_match[1]}-#{spaces_match[2]}.hf.space" if spaces_match

    datasets_match = stripped.match(HF_CO_DATASETS_REGEXP)
    return "https://huggingface.co/datasets/#{datasets_match[1]}/#{datasets_match[2]}/embed/viewer" if datasets_match

    raise StandardError, I18n.t("liquid_tags.huggingface_tag.invalid_url")
  end
end

UnifiedEmbed.register(HuggingfaceTag, regexp: HuggingfaceTag::REGISTRY_REGEXP)
