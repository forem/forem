class LivecodesTag < LiquidTagBase
  PARTIAL = "liquids/livecodes".freeze

  # Matches:
  #   https://livecodes.io
  #   https://livecodes.io?x=...            (no slash)
  #   https://livecodes.io/?x=...
  #   https://livecodes.io/?js=...&css=...  (any number of params)
  #   https://v49.livecodes.io/?x=...       (version subdomain)
  #   https://next.livecodes.io/?x=...      (named subdomain)
  #   https://livecodes.io/#config=code/... (hash config)
  REGISTRY_REGEXP =
    %r{\Ahttps://(?:[a-zA-Z0-9-]{1,20}\.)?livecodes\.io(?:/?|/?\?[^\s#]*|/?\#\S*)\z}

  # height must be 3-4 digits (100..9999 px)
  OPTION_REGEXP = /\Aheight=(?<height>\d{3,4})\z/
  DEFAULT_HEIGHT = 400

  def initialize(_tag_name, input, _parse_context)
    super
    # strip_tags first (it HTML-encodes entities in its output),
    # THEN decode entities so "&amp;" becomes "&" in the URL.
    stripped_input = CGI.unescape_html(strip_tags(input)).strip
    url, *options = stripped_input.split
    @src = parsed_src(url)
    @height = parsed_height(options)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        src: @src,
        height: "#{@height}px"
      },
    )
  end

  private

  def parsed_src(url)
    unless url&.match?(REGISTRY_REGEXP)
      raise StandardError, I18n.t("liquid_tags.livecodes_tag.invalid_livecodes_url")
    end

    url
  end

  def parsed_height(options)
    height = DEFAULT_HEIGHT

    options.each do |option|
      match = option.match(OPTION_REGEXP)
      unless match
        raise StandardError, I18n.t("liquid_tags.livecodes_tag.invalid_option", option: option)
      end

      height = match[:height].to_i
    end

    height
  end
end

Liquid::Template.register_tag("livecodes", LivecodesTag)
UnifiedEmbed.register(LivecodesTag, regexp: LivecodesTag::REGISTRY_REGEXP)
