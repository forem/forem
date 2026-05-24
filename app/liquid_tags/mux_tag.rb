class MuxTag < LiquidTagBase
  PARTIAL = "liquids/mux".freeze
  # Mux player URLs follow the pattern: https://player.mux.com/{video_id}
  # Video IDs are base64-encoded strings, typically alphanumeric with possible dashes/underscores
  REGISTRY_REGEXP = %r{https://player\.mux\.com/(?<video_id>[a-zA-Z0-9_-]+)(?:\?[\w=&-]+)?$}

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input  = strip_tags(input)
    unescaped_input = CGI.unescape_html(stripped_input)
    @id             = extract_video_id(unescaped_input)
    @width          = 710
    @height         = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        width: @width,
        height: @height
      },
    )
  end

  private

  def extract_video_id(input)
    input_params_removed = input.split("?")[0] # Remove query params for validation
    match = pattern_match_for(input_params_removed, [REGISTRY_REGEXP])
    raise StandardError, I18n.t("liquid_tags.mux_tag.invalid_mux_url") unless match

    match[:video_id]
  end
end

UnifiedEmbed.register(MuxTag, regexp: MuxTag::REGISTRY_REGEXP, skip_validation: true)

