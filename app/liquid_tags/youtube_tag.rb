class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze
  MARKER_TO_SECONDS_MAP = { "h" => 3600, "m" => 60, "s" => 1 }.freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @input = CGI.unescape_html(strip_tags(input.strip))
    @id = extract_video_id_and_start_time || raise(StandardError, "Invalid YouTube URL")
    @width = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(partial: PARTIAL, locals: { id: @id, width: @width, height: @height })
  end

  private

  def extract_video_id_and_start_time
    video_id = find_video_id(@input)
    return unless video_id

    time_parameter = find_time_parameter(@input)
    time_parameter ? "#{video_id}?start=#{parse_time(time_parameter)}" : video_id
  end

  def find_video_id(str)
    match = str.match(%r{youtu\.be/([a-zA-Z0-9_-]{11})}) ||
            str.match(%r{[?&]v=([a-zA-Z0-9_-]{11})}) ||
            str.match(/\A([a-zA-Z0-9_-]{11})\z/)
    match[1] if match
  end

  def find_time_parameter(str)
    match = str.match(/[?&](?:t|start)=([0-9hms]+)/i)
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

YOUTUBE_REGEX = %r{(?:youtu\.be/|youtube\.com/(?:watch|embed|shorts|live))}i
UnifiedEmbed.register(YoutubeTag, regexp: YOUTUBE_REGEX, skip_validation: true)