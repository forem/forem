class ClaudeArtifactTag < LiquidTagBase
  PARTIAL = "liquids/claude_artifact".freeze
  UUID_PATTERN = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
  REGISTRY_REGEXP = %r{\Ahttps://claude\.site/(?:public/)?artifacts/#{UUID_PATTERN}(?:/embed)?/?\z}i
  VALID_URL_REGEXP = %r{\Ahttps://claude\.site/(?:public/)?artifacts/(#{UUID_PATTERN})(?:/embed)?/?\z}i

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
    stripped_input = input.strip
    match = stripped_input.match(VALID_URL_REGEXP)
    raise StandardError, I18n.t("liquid_tags.claude_artifact_tag.invalid_url") unless match

    uuid = match[1]
    "https://claude.site/public/artifacts/#{uuid}/embed"
  end
end

Liquid::Template.register_tag("claudeartifact", ClaudeArtifactTag)
UnifiedEmbed.register(ClaudeArtifactTag, regexp: ClaudeArtifactTag::REGISTRY_REGEXP)
