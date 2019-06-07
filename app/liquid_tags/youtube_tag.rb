class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze

  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @width = 710
    @height = 399
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        id: @id,
        width: @width,
        height: @height
      },
    )
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    raise StandardError, "Invalid YouTube ID" unless valid_id?(input_no_space)
    return translate_start_time(input_no_space) if input_no_space.include?("?t=")

    input_no_space
  end

  def translate_start_time(id)
    time = id.split("?t=")[-1]
    time_hash = {
      h: time.scan(/\d+h/)[0]&.delete("h").to_i,
      m: time.scan(/\d+m/)[0]&.delete("m").to_i,
      s: time.scan(/\d+s/)[0]&.delete("s").to_i
    }
    time_in_seconds = (time_hash[:h] * 3600) + (time_hash[:m] * 60) + time_hash[:s]
    "#{id.split('?t=')[0]}?start=#{time_in_seconds}"
  end

  def valid_id?(id)
    id =~ /\A[a-zA-Z0-9_-]{11}((\?t\=)?(\d{1}h)?(\d{1,2}m)?(\d{1,2}s)?){5,11}?\Z/
  end
end

Liquid::Template.register_tag("youtube", YoutubeTag)
