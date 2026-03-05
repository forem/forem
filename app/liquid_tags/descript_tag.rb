class DescriptTag < LiquidTagBase
  PARTIAL = "liquids/descript".freeze
  REGISTRY_REGEXP = %r{https?://(?:www\.)?share\.descript\.com/view/(?<share_id>[a-zA-Z0-9]+)(?:[/?#].*)?$}

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input  = strip_tags(input)
    unescaped_input = CGI.unescape_html(stripped_input)
    @id             = extract_share_id(unescaped_input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id
      },
    )
  end

  def extract_share_id(input)
    input_params_removed = input.split(/[?#]/)[0].chomp("/")
    match = pattern_match_for(input_params_removed, [REGISTRY_REGEXP])
    raise StandardError, I18n.t("liquid_tags.descript_tag.invalid_descript_url") unless match

    match[:share_id]
  end
end

UnifiedEmbed.register(DescriptTag, regexp: DescriptTag::REGISTRY_REGEXP)
