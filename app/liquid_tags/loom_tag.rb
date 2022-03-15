class LoomTag < LiquidTagBase
  PARTIAL = "liquids/loom".freeze
  REGISTRY_REGEXP = %r{https://(?:www\.)?loom\.com/(?:share|embed)/(?<video_id>[a-zA-Z0-9]+)(?:\?[\w=-]+)?$}

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input  = strip_tags(input)
    unescaped_input = CGI.unescape_html(stripped_input)
    @id             = extract_video_id(unescaped_input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id
      },
    )
  end

  def extract_video_id(input)
    input_params_removed = input.split("?")[0] # Loom URLs with params fail valid-URL check
    match = pattern_match_for(input_params_removed, [REGISTRY_REGEXP])
    raise StandardError, I18n.t("liquid_tags.loom_tag.invalid_loom_url") unless match

    match[:video_id]
  end
end

UnifiedEmbed.register(LoomTag, regexp: LoomTag::REGISTRY_REGEXP)
