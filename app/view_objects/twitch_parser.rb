class TwitchParser
  TWITCH_HOST_REGEX = /\A(?:player\.|www\.)?twitch\.tv\z/i

  def initialize(url)
    @url = url.to_s.strip
  end

  def call
    return nil if url.blank? || !twitch_video_url?

    twitch_embed_url
  end

  def video_id
    return nil unless twitch_video_url?

    extract_video_id
  end

  private

  attr_reader :url

  def twitch_video_url?
    uri = parse_uri
    return false unless uri&.host

    host = uri.host.downcase
    return false unless host.match?(TWITCH_HOST_REGEX)

    extract_video_id.present?
  end

  def twitch_embed_url
    video_id = extract_video_id
    return nil unless video_id

    parent = parent_url
    "https://player.twitch.tv/?video=#{video_id}&parent=#{parent}&autoplay=false"
  end

  def extract_video_id
    uri = parse_uri
    return unless uri

    host = uri.host.downcase

    # Handle player.twitch.tv/?video=VIDEO_ID format
    if host == "player.twitch.tv"
      params = Rack::Utils.parse_query(uri.query.to_s)
      return params["video"] if params["video"].present?
    end

    # Handle www.twitch.tv/videos/VIDEO_ID format
    if host == "www.twitch.tv" || host == "twitch.tv"
      path = uri.path.to_s
      return unless path

      segments = path.split("/").reject(&:blank?)
      # Look for /videos/VIDEO_ID pattern
      videos_index = segments.index("videos")
      return segments[videos_index + 1] if videos_index && segments[videos_index + 1]

      # Also check if path starts with /videos/
      return path.split("/videos/")[1]&.split("/")&.first if path.include?("/videos/")
    end

    nil
  rescue StandardError
    nil
  end

  def parent_url
    Settings::General.app_domain.split(":")[0]
  end

  def parse_uri
    @parse_uri ||= URI.parse(url)
  rescue URI::InvalidURIError
    nil
  end
end

