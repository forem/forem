class CodesandboxTag < LiquidTagBase
  PARTIAL = "liquids/codesandbox".freeze
  REGISTRY_REGEXP = %r{https?://(?:www|app\.)?(?:codesandbox\.io/embed/)(?<id>[\w-]{,60})(?:\?)?(?<options>\S+)?}
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
    return [match[:id], parse_options(match[:options]&.split("&"))] if match

    id = input.split.first
    raise StandardError, I18n.t("liquid_tags.codesandbox_tag.invalid_id") unless valid_id?(id)

    [id, parse_options(extract_options(input))]
  end

  def valid_id?(id)
    id =~ /\A[\w-]{,60}\Z/
  end

  def extract_options(input)
    _, *options = input.split
    options
  end

  def parse_options(options)
    return if options.blank?

    query = options.filter_map { |option| option if valid_option(option) }.join("&")

    query.blank? ? query : "?#{query}"
  end

  def valid_option(option)
    (option =~ OPTIONS_REGEXP)&.zero?
  end
end

Liquid::Template.register_tag("codesandbox", CodesandboxTag)

UnifiedEmbed.register(CodesandboxTag, regexp: CodesandboxTag::REGISTRY_REGEXP)
