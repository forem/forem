require "securerandom"

class ObservablehqTag < LiquidTagBase
  PARTIAL = "liquids/observablehq".freeze
  VALID_ID_REGEX =
    %r{
      (\A([a-zA-Z0-9](-?[a-zA-Z0-9-]){0,128})\Z| # for single id patter
      \A@([a-zA-Z0-9](-?[a-zA-Z0-9-]){0,128})/([a-zA-Z0-9-]){1,128}(/[a-zA-Z0-9]+)?\Z) # check for @user/notebook-title
    }x
      .freeze

  def initialize(_tag_name, input, _parse_context)
    super
    stripped_link = ActionController::Base.helpers.strip_tags(input)
    the_input = stripped_link.split(" ").first
    @iframeid = SecureRandom.uuid
    @embedded_url = ObservablehqTag.embedded_url(the_input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @embedded_url,
        iframeid: @iframeid
      },
    )
  end

  def self.embedded_url(the_input)
    parse_link(the_input)
  end

  def self.parse_link(the_input)
    # Test Ids remove params if exists
    input_no_space = the_input.delete(" ").split("?")[0]
    raise_error(input_no_space, "URL ID") unless valid_param?(input_no_space)

    # Test URL params
    begin
      url = URI("https://observablehq.com/embed/#{the_input}")
    rescue StandardError
      raise_error(the_input, "URL params")
    end

    url.to_s
  end

  def self.raise_error(the_input, msg)
    raise StandardError, "Invalid #{msg} on ObservablqHQ input: #{the_input}"
  end

  def self.valid_param?(value)
    (value =~ VALID_ID_REGEX)&.zero?
  end
end

Liquid::Template.register_tag("observablehq", ObservablehqTag)
