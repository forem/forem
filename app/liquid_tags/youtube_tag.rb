class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze
  EMBED_ORIGIN = "https://www.youtube.com".freeze
  NOCOOKIE_EMBED_ORIGIN = "https://www.youtube-nocookie.com".freeze
  NOCOOKIE_HOST_REGEX = /\A(?:www\.)?youtube-nocookie\.com\z/i
  MARKER_TO_SECONDS_MAP = { "h" => 3600, "m" => 60, "s" => 1 }.freeze

  def self.extract_video_id(str)
    match = str.match(%r{youtu\.be/([a-zA-Z0-9_-]{11})}) ||
      str.match(/[?&]v=([a-zA-Z0-9_-]{11})/) ||
      str.match(/\A([a-zA-Z0-9_-]{11})\z/)
    match[1] if match
  end

  def initialize(_tag_name, input, _parse_context)
    super
    @input = CGI.unescape_html(strip_tags(input.strip))
    @id = extract_video_id_and_start_time || raise(StandardError, "Invalid YouTube URL")
    @shorts = shorts_url?
    @origin = embed_origin
    @width = @shorts ? 315 : 710
    @height = @shorts ? 560 : 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        origin: @origin,
        shorts: @shorts,
        width: @width,
        height: @height
      },
    )
  end

  private

  def extract_video_id_and_start_time
    video_id = find_video_id(@input)
    return unless video_id

    time_parameter = find_time_parameter(@input)
    time_parameter ? "#{video_id}?start=#{parse_time(time_parameter)}" : video_id
  end

  # The iframe origin is always one of two fixed constants, chosen by the
  # parsed host of the submitted URL. The submitted URL is never used as src.
  def embed_origin
    nocookie_host? ? NOCOOKIE_EMBED_ORIGIN : EMBED_ORIGIN
  end

  def nocookie_host?
    uri = URI.parse(@input.match?(%r{\Ahttps?://}i) ? @input : "https://#{@input}")
    uri.host.to_s.match?(NOCOOKIE_HOST_REGEX)
  rescue URI::InvalidURIError
    false
  end

  def shorts_url?
    @input.include?("youtube.com/shorts/")
  end

  def find_video_id(str)
    match = str.match(%r{youtu\.be/([a-zA-Z0-9_-]{11})}) ||
      str.match(%r{youtube(?:-nocookie)?\.com/(?:shorts|live|embed|v)/(?!videoseries)([a-zA-Z0-9_-]{11})}) ||
      str.match(/[?&]v=([a-zA-Z0-9_-]{11})/) ||
      str.match(/\A([a-zA-Z0-9_-]{11})\z/)
    match[1] if match
  end

  def find_time_parameter(str)
    match = str.match(/[?&#](?:t|start)=([0-9hms]+)/i)
    match[1] if match
  end

  def parse_time(time_str)
    return time_str.to_i if time_str.match?(/^\d+$/)

    time_str.scan(/(\d+)([hms])/).reduce(0) do |total, (amount, marker)|
      total + (amount.to_i * MARKER_TO_SECONDS_MAP[marker])
    end
  end
end

Liquid::Template.register_tag("youtube", YoutubeTag)

YOUTUBE_REGEX = %r{(?:youtu\.be/|youtube(?:-nocookie)?\.com/(?:watch|embed|shorts|live|v/))}i
UnifiedEmbed.register(YoutubeTag, regexp: YOUTUBE_REGEX, skip_validation: true)
