class CodesandboxTag < LiquidTagBase
  PARTIAL = "liquids/codesandbox".freeze
  OPTIONS_REGEXP =
    %r{\A(initialpath=([a-zA-Z0-9\-_/.@%])+)\Z|
      \A(module=([a-zA-Z0-9\-_/.@%])+)\Z|
      \A(runonclick=((0|1){1}))\Z|
      \Aview=(editor|split|preview)\Z}x

  def initialize(_tag_name, id, _parse_context)
    super
    @id = parse_id(id)
    @query = parse_options(id)
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

  def parse_id(input)
    id = input.split.first
    raise StandardError, "CodeSandbox Error: Invalid ID" unless valid_id?(id)

    id
  end

  def valid_id?(id)
    id =~ /\A[a-zA-Z0-9\-]{0,60}\Z/
  end

  def parse_options(input)
    _, *options = input.split

    options.map { |option| valid_option(option) }.reject(&:nil?)

    query = options.join("&")

    if query.blank?
      query
    else
      "?#{query}"
    end
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
