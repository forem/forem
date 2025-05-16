class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze

  MARKER_TO_SECONDS_MAP = {
    "h" => 60 * 60,
    "m" => 60,
    "s" => 1
  }.freeze

  def initialize(_tag_name, input, _parse_context)
    super

    @input = CGI.unescape_html(strip_tags(input.strip))
    @id = extract_video_id || raise(StandardError, "Invalid YouTube ID or URL")
    @width = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        width: @width,
        height: @height
      },
    )
  end

  private

  def extract_video_id
    input = @input.to_s.strip
    video_id = nil
    time_parameter = nil
    case input
    when %r{(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|shorts/|live/))([^?&#/]+)}i
      video_id = $1
    else
      parts = input.split(/[?#&\/]/)
      video_id_candidate = parts.first
      video_id = video_id_candidate if video_id_candidate&.match?(/\A[a-zA-Z0-9_-]{11}\z/)
    end
    if input =~ /[?&#](?:t|start)=([0-9hms]+)(?:$|&)/i
      time_parameter = $1
    end
    unless video_id && video_id.match?(/\A[a-zA-Z0-9_-]{11}\z/)
      raise StandardError, "Invalid YouTube ID or URL"
    end
    time_parameter ? "#{video_id}?start=#{parse_time(time_parameter)}" : video_id
  end
  def parse_time(time_str)
    return time_str.to_i if time_str.match?(/^\d+$/)
    
    seconds = 0
    time_str.scan(/(\d+)([hms])/) do |amount, marker|
      seconds += amount.to_i * MARKER_TO_SECONDS_MAP[marker]
    end
    
    seconds
  end
end

Liquid::Template.register_tag("youtube", YoutubeTag)
YOUTUBE_REGEX = %r{(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|shorts/|live/))}i
UnifiedEmbed.register(YoutubeTag, regexp: YOUTUBE_REGEX)
