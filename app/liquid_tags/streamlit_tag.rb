class StreamlitTag < LiquidTagBase
  PARTIAL = "liquids/streamlit".freeze
  REGISTRY_REGEXP = %r{\Ahttps://[\w-]+\.streamlit\.app(?:/[\w.-]*)*/?\z}
  VALID_URL_REGEXP = %r{\Ahttps://([\w-]+\.streamlit\.app(?:/[\w.-]*)*)/?\z}

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
    raise StandardError, I18n.t("liquid_tags.streamlit_tag.invalid_url", default: "Invalid Streamlit URL") unless match

    "https://#{match[1].chomp('/')}?embed=true"
  end
end

Liquid::Template.register_tag("streamlit", StreamlitTag)
UnifiedEmbed.register(StreamlitTag, regexp: StreamlitTag::REGISTRY_REGEXP)
