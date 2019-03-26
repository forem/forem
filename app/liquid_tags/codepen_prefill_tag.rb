class CodepenPrefillTag < Liquid::Block
  def initialize(tag_name, options, tokens)
    super
    @options = parse_options(options)
  end

  def render(context)
    content = Nokogiri::HTML(super)
    # parsed_content = content.xpath("//html/body").text # dont parse for text???
    html = <<~HTML
      <div
        class="codepen"
        data-height="400"
        data-editable=true
        data-prefill='#{@options}'
        >
        #{content}
      </div>
      <script async src="https://static.codepen.io/assets/embed/ei.js"></script>
    HTML
    html
  end

  def parse_options(input)
    stripped_input = ActionController::Base.helpers.strip_tags(input)
    options = stripped_input.split(" ")
    options.map { |o| valid_option(o) }.reject(&:nil?)

    prefill = {}
    options.each do |i|
      key = i.split("=")[0]
      val = i.split("=")[1]
      val = val.split(",") if i.include? ","
      prefill[key] = val
    end

    prefill.to_json
  end

  def valid_option(option)
    raise StandardError, "CodepenPrefill Error: Invalid options" unless option =~ /^[A-Za-z-]+={1}[\[\]]?["\w.,"]*[\[\]]?/

    option
  end
end

Liquid::Template.register_tag("codepenprefill", CodepenPrefillTag)
