class SpotifyTag < LiquidTagBase
  PARTIAL = "liquids/spotify".freeze
  # rubocop:disable Layout/LineLength
  REGISTRY_REGEXP = %r{https?://(?:open.spotify.com/)(?<type>track|artist|playlist|album|episode|show)/(?<id>\w{,22})(?:\?si=[\w-]+)?}
  # rubocop:enable Layout/LineLength
  URI_REGEXP = /\A(?:spotify):(?<type>track|artist|playlist|album|episode|show):(?<id>\w{22})\Z/
  URI_PLAYLIST_REGEXP = /\A(?:spotify):(?:user):(?<type>[a-zA-Z0-9]+):(?:playlist):(?<id>\w{22})\Z/ # legacy support
  REGEXP_OPTIONS = [REGISTRY_REGEXP, URI_REGEXP, URI_PLAYLIST_REGEXP].freeze
  TYPE_HEIGHT = {
    track: 80,
    user: 380,
    artist: 380,
    album: 380,
    playlist: 380,
    episode: 232,
    show: 232
  }.freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @type, @id = parse_input(strip_tags(input))
    @height = TYPE_HEIGHT[@type.to_sym]
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        type: @type,
        id: @id,
        height: @height
      },
    )
  end

  private

  def parse_input(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, "Invalid Spotify URI or URL." unless match

    [match[:type], match[:id]]
  end
end

Liquid::Template.register_tag("spotify", SpotifyTag)

UnifiedEmbed.register(SpotifyTag, regexp: SpotifyTag::REGISTRY_REGEXP)
