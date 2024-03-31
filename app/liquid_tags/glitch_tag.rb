class GlitchTag < LiquidTagBase
  attr_accessor :uri

  PARTIAL = "liquids/glitch".freeze

  REGISTRY_REGEXP = %r{https://(?:(?<subdomain>[\w-]{1,110})\.)?glitch(?:\.me|\.com)(?:/edit/#!/)?(?<slug>[\w-]{1,110})?(?<params>\?.*)?}
  ID_REGEXP = /\A(?:^~)?(?<slug>[\w-]{1,110})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, ID_REGEXP].freeze
  # last part of PATH_REGEX handles line & character numbers that may appear at path end
  PATH_REGEX = %r{path=(?<path>[\w/\-.]*)[\d:]*}
  OPTION_REGEXP = %r{(app|code|no-files|preview-first|no-attribution|file=([\w/\-.]+)?)}
  OPTIONS_TO_QUERY_PAIR = {
    "app" => %w[previewSize 100],
    "code" => %w[previewSize 0],
    "no-files" => %w[sidebarCollapsed true],
    "preview-first" => %w[previewFirst true],
    "no-attribution" => %w[attributionHidden true]
  }.freeze

  def initialize(_tag_name, input, _parse_context)
    super

    unescaped_input = CGI.unescape_html(input)
    stripped_input  = strip_tags(unescaped_input)
    @id, @query = parsed_input(stripped_input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        query: @query
      },
    )
  end

  private

  def parsed_input(input)
    id, *options = input.split
    match = pattern_match_for(id, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.glitch_tag.invalid_glitch_id") unless match

    [get_slug(match), parse_options(options, match)]
  end

  def get_slug(match)
    if match_has_named_capture_group?(match, "subdomain")
      match[:subdomain]
    else
      match[:slug]
    end
  end

  def parse_options(options, match)
    # 'app' and 'code' should cancel each other out
    options -= %w[app code] if options.include?("app") && options.include?("code")

    # check for file= in options, then path= in params; fallback is file=index.html
    file_option = options.detect { |option| option.start_with?("file=") }
    options += ["file=#{path_within_params(match)}"] unless file_option

    validated_options = options.select { |option| valid_option?(option) }
    raise StandardError, I18n.t("liquid_tags.glitch_tag.invalid_options") if validated_options.empty?

    build_options(validated_options)
  end

  def path_within_params(match)
    return "index.html" unless match_has_named_capture_group?(match, "params")

    return "index.html" if match[:params].blank?

    path_match = pattern_match_for(match[:params], [PATH_REGEX])
    return "index.html" if path_match.blank?

    path_match[:path]
  end

  def valid_option?(option)
    option.match?(OPTION_REGEXP)
  end

  def build_options(options)
    # Convert options to query param pairs
    params = options.filter_map { |option| OPTIONS_TO_QUERY_PAIR[option] }

    # by this point, there is always a 'file='
    path = options
      .detect { |option| option.start_with?("file=") }
      .delete_prefix("file=")

    params.push ["path", path]

    # Encode the resulting pairs as a query string
    URI.encode_www_form(params)
  end
end

Liquid::Template.register_tag("glitch", GlitchTag)

UnifiedEmbed.register(GlitchTag, regexp: GlitchTag::REGISTRY_REGEXP)
