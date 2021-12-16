class CodesandboxTag < LiquidTagBase
  PARTIAL = "liquids/codesandbox".freeze
  # rubocop:disable Layout/LineLength
  REGISTRY_REGEXP = %r{https?://(?:www|app\.)?(?:codesandbox\.io/embed/)(?<video_id>[a-zA-Z0-9-]{0,60})(?:\?)?(?<options>\S+)}
  # rubocop:enable Layout/LineLength
  OPTIONS_REGEXP =
    %r{\A(initialpath=([a-zA-Z0-9\-_/.@%])+)\Z|
      \A(file=([a-zA-Z0-9\-_/.@%])+)\Z|
      \A(module=([a-zA-Z0-9\-_/.@%])+)\Z|
      \A(runonclick=((0|1){1}))\Z|
      \Aview=(editor|split|preview)\Z}x

  def initialize(_tag_name, id, _parse_context)
    super
    input       = CGI.unescape_html(strip_tags(id))
    @id, @query = parse_id_or_url_and_options(input)
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

  def parse_id_or_url_and_options(input)
    match = pattern_match_for(input, [REGISTRY_REGEXP])
    return [match[:video_id], parse_options(match[:options].split("&"))] if match

    id = input.split.first
    raise StandardError, "CodeSandbox Error: Invalid ID" unless valid_id?(id)

    [id, parse_options(extract_options(input))]
  end

  def valid_id?(id)
    id =~ /\A[a-zA-Z0-9\-]{0,60}\Z/
  end

  def extract_options(input)
    _, *options = input.split
    options
  end

  def parse_options(options)
    options.map { |option| valid_option(option) }.reject(&:nil?)

    query = options.join("&")

    query.blank? ? query : "?#{query}"
  end

  # Valid options must start with 'initialpath=' or 'module=' and a string of at least 1 length
  # composed of letters, numbers, dashes, underscores, forward slashes, @ signs, periods/dots,
  # and % symbols.  Invalid options will raise an exception
  def valid_option(option)
    raise StandardError, "CodeSandbox Error: Invalid options" unless (option =~ OPTIONS_REGEXP)&.zero?

    option
  end
end

Liquid::Template.register_tag("codesandbox", CodesandboxTag)

UnifiedEmbed.register(CodesandboxTag, regexp: CodesandboxTag::REGISTRY_REGEXP)
