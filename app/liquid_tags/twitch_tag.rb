class TwitchTag < LiquidTagBase
  PARTIAL = "liquids/twitch".freeze
  REGISTRY_REGEXP = %r{https://(?:clips|player|www).twitch.tv/(?:(?:embed\?clip=|\w+/clip/)|(?:\?video=|videos/))(?<id>[a-zA-Z0-9-]{,100})(?:&[^$]+)?}
  VALID_VIDEO_REGEXP = /\A(?<video_id>\d+)\Z/
  VALID_CLIP_REGEXP = /\A(?<clip_slug>[a-zA-Z0-9-]{,100})\Z/
  REGEXP_OPTIONS = [VALID_VIDEO_REGEXP, VALID_CLIP_REGEXP, REGISTRY_REGEXP].freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @url = parsed_input(strip_tags(input))
    @width = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @url,
        width: @width,
        height: @height
      },
    )
  end

  private

  # The `parsed_input` method handles two Twitch Liquid Tag use-cases:
  # `{% twitch <video_id or clip_slug> %}`
  # `{% embed <url> %}`
  #
  # The iframe src for a video is different from that for a clip.
  #
  # In the case of a video_id or clip_slug, this method validates the input
  # and then returns the appropriate src.
  #
  # In the case of a url, this method validates the input, then determines
  # whether the id contained in the url is a video_id or clip_slug.
  #
  # Seeing as the clip_slug regexp would match a video_id, the check
  # against the video_id regexp occurs first 😅

  def parsed_input(input)
    input = input.split("&")[0] # prevent param injection

    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, "Invalid Twitch ID, Slug or URL" unless match

    return player_url(match[:video_id]) if match.names.include?("video_id")
    return clip_url(match[:clip_slug]) if match.names.include?("clip_slug")
    return player_or_clip_url(match) if match.names.include?("id")
  end

  def clip_url(id)
    "https://clips.twitch.tv/embed?clip=#{id}&parent=#{parent_url}&autoplay=false"
  end

  def player_url(id)
    "https://player.twitch.tv/?video=#{id}&parent=#{parent_url}&autoplay=false"
  end

  def player_or_clip_url(match)
    return player_url(match[:id]) if match[:id].match?(VALID_VIDEO_REGEXP)
    return clip_url(match[:id]) if match[:id].match?(VALID_CLIP_REGEXP)
  end

  def parent_url
    Settings::General.app_domain.split(":")[0]
  end
end

Liquid::Template.register_tag("twitch", TwitchTag)

UnifiedEmbed.register(TwitchTag, regexp: TwitchTag::REGISTRY_REGEXP)
