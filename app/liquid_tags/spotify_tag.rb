class SpotifyTag < LiquidTagBase
  PARTIAL = "liquids/spotify".freeze
  URI_REGEXP = /spotify:(track|user|artist|album|episode):\w{22}/.freeze
  TYPE_HEIGHT = {
    track: 80,
    user: 330,
    artist: 240,
    album: 240,
    episode: 80
  }.freeze

  def initialize(tag_name, uri, tokens)
    super
    @parsed_uri = generate_embed_link(parse_uri(uri))
    @height = TYPE_HEIGHT[@parsed_uri[1].to_sym]
  end

  def render(_context)
    ActionController.Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        parsed_uri: @parsed_uri,
        height: @height
      },
    )
  end

  private

  def parse_uri(uri)
    URI_REGEXP.match(uri) || raise_error
  end

  def generate_embed_link(parsed_uri)
    parsed_uri.string.split(":")[1..-1].unshift("https://open.spotify.com/embed").join("/")
  end

  def raise_error
    raise StandardError, "Invalid Spotify Link - Be sure you're using the uri of a specific track, album, artist, playlist, or podcast episode."
  end
end

Liquid::Template.register_tag("spotify", SpotifyTag)
