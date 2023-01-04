require "uri"

class DotnetFiddleTag < LiquidTagBase
  PARTIAL = "liquids/dotnetfiddle".freeze
  REGISTRY_REGEXP = %r{https://dotnetfiddle\.net(?:/Widget)?/(?<id>[\w-]+)}

  def initialize(_tag_name, link, _parse_context)
    super
    @link = parse_link(strip_tags(link))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        height: 600
      },
    )
  end

  private

  def parse_link(link)
    match = pattern_match_for(link, [REGISTRY_REGEXP])
    raise StandardError, I18n.t("liquid_tags.dotnet_fiddle_tag.invalid_dotnetfiddle_url") unless match

    insert_widget(link, match)
  end

  def insert_widget(link, match)
    uri = URI(link)
    return link if uri.path.include?("Widget")

    "https://dotnetfiddle.net/Widget/#{match[:id]}"
  end
end

Liquid::Template.register_tag("dotnetfiddle", DotnetFiddleTag)

UnifiedEmbed.register(DotnetFiddleTag, regexp: DotnetFiddleTag::REGISTRY_REGEXP)
