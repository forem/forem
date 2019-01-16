class SpotifyTag < LiquidTagBase
  URI_REGEXP = /spotify:(track|user|artist|album|episode).+(?<=:)\w{22}/.freeze
  TYPE_HEIGHT = {
    track: 116,
    user: 116,
    artist: 116,
    album: 116,
    episode: 116
  }.freeze

  def initialize(tag_name, uri, tokens)
    super
    @parsed_uri = parse_uri(uri)
    @height = TYPE_HEIGHT[@parsed_uri[1]]
  end

  def render(_context)
    html = <<-HTML
      <iframe
        width="100%"
        height="#{@height}px"
        scrolling="no"
        frameborder="0"
        allowtransparency="true"
        allow="encrypted-media"
        src="#{generate_embed_link(@parsed_uri)}">
      </iframe>
    HTML
    finalize_html(html)
  end

  private

  def parse_uri(uri)
    URI_REGEXP.match(uri) || raise_error
  end

  def generate_embed_link(parsed_uri)
    parsed_uri.split(":")[1..-1].unshift("https://open.spotify.com/embed").join("/")
  end

  def raise_error
    raise StandardError, "Invalid Spotify Link - Be sure you're using the uri of a specific track, album, artist, playlist, or podcast episode."
  end
end

Liquid::Template.register_tag("spotify", SpotifyTag)
