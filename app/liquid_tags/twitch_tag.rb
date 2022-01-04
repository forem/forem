class TwitchTag < LiquidTagBase
  PARTIAL = "liquids/twitch".freeze
  REGISTRY_REGEXP = %r{https://(?:clips|player|www).twitch.tv/(?:(?:embed\?clip=|\w+/clip/)|(?:\?video=|videos/))(?<id>[a-zA-Z0-9-]{,100})(?:&[^$]+)?}
  VALID_VIDEO_REGEXP = /\A(?<video_id>\d+)\Z/
  VALID_CLIP_REGEXP = /\A(?<clip_id>[a-zA-Z0-9-]{,100})\Z/
  REGEXP_OPTIONS = [VALID_VIDEO_REGEXP, VALID_CLIP_REGEXP].freeze

  # MY NOTES
  # The Twitch URL is either player.twitch or clips.twitch
  # A player URL has ?video= and clip URL has embed?clip=
  # For unfiedembed, validate, parse and use the whole url in the src
  # For id only tag, determine which url type (all numbers => player, mix => clip)
  # then build url and insert into src

  def initialize(_tag_name, input, _parse_context)
    super
    # @parent = parsed_url(Settings::General.app_domain)
    @url = parsed_input(strip_tags(input))
    @width = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        # parent: @parent,
        url: @url,
        width: @width,
        height: @height
      },
    )
  end

  private

  # Strip out port number because it confuses Twitch
  # def parsed_url(input)
  #   input.split(":")[0]
  # end

  def parent_url
    Settings::General.app_domain.split(":")[0]
  end

  def clip_url(id)
    "https://clips.twitch.tv/embed?clip=#{id}&parent=#{parent_url}&autoplay=false"
  end

  def player_url(id)
    "https://player.twitch.tv/?video=#{id}&parent=#{parent_url}&autoplay=false"
  end

  def parsed_input(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, "Invalid YouTube ID" unless match

    player_url(match[:video_id]) if match.names.include?("video_id")
    clip_url(match[:clip_id]) if match.names.include?("clip_id")

    # input.strip.split("&")[0]
  end
end

Liquid::Template.register_tag("twitch", TwitchTag)

UnifiedEmbed.register(TwitchTag, regexp: TwitchTag::REGISTRY_REGEXP)
