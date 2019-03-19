class CodepenPrefillTag < Liquid::Block
  def initialize(tag_name, options)
    super
    @options = parse_options(options)
  end

  def render(context)
    # options used here to define Codepen html tag options below
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text
    html = <<~HTML
      <div
        class="codepen"
        data-prefill=#{@options}
        >

        #{parsed_content}

      </div>
      <script async src="https://static.codepen.io/assets/embed/ei.js"></script>
    HTML
    html
  end

  def parse_options(input)
    _, *options = input.split(" ")

    options.map { |o| valid_option(o) }.reject(&:nil?)

    query = {}
    options.each do |i|
      attr = i.split("=")[0]
      val = i.split("=")[1]
      query[attr] = val
    end

    query.to_json
  end

  def valid_option(option)
    raise StandardError, "CodepenPrefill Error: Invalid options" unless option =~ /^[A-Za-z-]+={1}[\[\]]?["\w.,"]*[\[\]]?/

    option
  end
end

Liquid::Template.register_tag("codepenprefill", CodepenPrefillTag)
