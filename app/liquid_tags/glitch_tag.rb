class GlitchTag < LiquidTagBase
  attr_accessor :uri

  PARTIAL = "liquids/glitch".freeze

  REGISTRY_REGEXP = %r{https://(?<slug_subdomain>[\w\-]{1,110}.)?glitch(?:.me|.com)(?:/edit/#!/)?(?<slug>[\w\-]{1,110})?(?<params>\?.*)?}
  ID_REGEXP = /\A(?<slug>[\w\-]{1,110})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, ID_REGEXP].freeze
  # last part of PATH_REGEX handles line & character numbers added to filename
  PATH_REGEX = %r{path=(?:(?<path>[\w/\-.]+)(?:[\d:]+)?)?}
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
    stripped_id = id.delete("~") # remove possible preceeding tilde
    match = pattern_match_for(stripped_id, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.glitch_tag.invalid_glitch_id") unless match

    [get_slug(match), parse_options(options, match)]
  end

  def get_slug(match)
    # the dot comes through the regex
    return match[:slug_subdomain]&.delete(".") if match[:slug_subdomain].present?

    match[:slug]
  end

  def parse_options(options, match)
    # 'app' and 'code' should cancel each other out
    options -= %w[app code] if (options & %w[app code]) == %w[app code]
    # add file= to options if a path is present within the URL params
    options += ["file=#{path_within_params(match)}"] if path_within_params(match)

    return if options.blank?

    validated_options = options.select { |option| valid_option?(option) }
    raise StandardError, I18n.t("liquid_tags.glitch_tag.invalid_options") if validated_options.empty?

    build_options(validated_options)
  end

  # TODO: See if you can get these to work without the match_has method
  def path_within_params(match)
    return unless match_has_named_capture_group?(match, "params")

    path_match = pattern_match_for(match[:params], [PATH_REGEX])

    return unless match_has_named_capture_group?(path_match, "path")

    path_match[:path]
  end

  def match_has_named_capture_group?(match, group_name)
    match.names.include?(group_name)
  end

  def valid_option?(option)
    option.match?(OPTION_REGEXP)
  end

  def build_options(options)
    # Convert options to query param pairs
    params = options.filter_map { |option| OPTIONS_TO_QUERY_PAIR[option] }

    # Deal with the file option if present or use default
    file_option = options.detect { |option| option.start_with?("file=") }
    path = file_option ? (file_option.sub! "file=", "") : "index.html"
    params.push ["path", path]

    # Encode the resulting pairs as a query string
    URI.encode_www_form(params)
  end
end

Liquid::Template.register_tag("glitch", GlitchTag)

UnifiedEmbed.register(GlitchTag, regexp: GlitchTag::REGISTRY_REGEXP)
