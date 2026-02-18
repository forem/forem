class MuxParser
  MUX_PLAYER_HOST = "player.mux.com".freeze

  def initialize(url)
    @url = url.to_s.strip
  end

  def call
    return nil if url.blank? || !mux_url?

    mux_embed_url
  end

  def video_id
    return nil unless mux_url?

    extract_video_id
  end

  private

  attr_reader :url

  def mux_url?
    uri = parse_uri
    return false unless uri&.host

    host = uri.host.downcase
    return false unless host == MUX_PLAYER_HOST

    extract_video_id.present?
  end

  def mux_embed_url
    video_id = extract_video_id
    "https://player.mux.com/#{video_id}"
  end

  def extract_video_id
    uri = parse_uri
    return unless uri

    # Extract video ID from path: /{video_id} or /{video_id}?params
    path = uri.path.to_s
    return if path.blank? || path == "/"

    # Remove leading slash and any query params
    video_id = path.sub(%r{\A/}, "").split("?")[0]
    video_id.presence
  rescue StandardError
    nil
  end

  def parse_uri
    @parse_uri ||= URI.parse(url)
  rescue URI::InvalidURIError
    nil
  end
end

