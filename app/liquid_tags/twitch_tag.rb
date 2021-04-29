class TwitchTag < LiquidTagBase
  PARTIAL = "liquids/twitch".freeze

  def initialize(_tag_name, slug, _parse_context)
    super
    @url = parsed_url(Settings::General.app_domain)
    @slug = parsed_slug(slug)
    @width = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @url,
        slug: @slug,
        width: @width,
        height: @height
      },
    )
  end

  private

  # Strip out port number because it confuses Twitch
  def parsed_url(url)
    url.split(":")[0]
  end

  # prevent param injection
  def parsed_slug(slug)
    slug.strip.split("&")[0]
  end
end

Liquid::Template.register_tag("twitch", TwitchTag)
