class CodesandboxTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @query = parse_options(id)
  end

  def render(_context)
    '<iframe src="https://codesandbox.io/embed/' + @id + @query + '"
      style="width:100%; height:calc(300px + 8vw); border:0; border-radius: 4px; overflow:hidden;"
      sandbox="allow-same-origin allow-scripts allow-forms allow-top-navigation-by-user-activation"
    </iframe>'
  end

  private

  def parse_id(input)
    id = input.split(" ").first
    raise StandardError, "Invalid codesandbox ID" unless valid_id?(id)

    id
  end

  def valid_id?(id)
    id =~ /\A[a-zA-Z0-9\-]{0,60}\Z/
  end

  def parse_options(input)
    _, *options = input.split(" ")

    # Validation
    validated_options = options.map { |o| valid_option(o) }.reject { |e| e == nil }
    raise StandardError, "Invalid Options" unless options.empty? || !validated_options.empty?

    query = options.join("&")

    if query.blank?
      query
    else
      "?#{query}"
    end
  end

  def valid_option(option)
    if option.start_with?("initalpath=", "module=")
      option
    else
      ""
    end
  end
end

Liquid::Template.register_tag("codesandbox", CodesandboxTag)
