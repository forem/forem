require "json"

class CodepenPrefillTag < LiquidTagBase
  def initialize(tag_name, options, markup)
    super
    @draft = sanitize_draft(markup)
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

        <code style="display: none">#{@preamble}</code>
        <code>#{parsed_content}</code>
      </div>
    HTML
    # change HTML format above to match Codepen Prefill
    html
  end

  def sanitize_draft(markup)
    ActionView::Base.full_sanitizer.sanitize(markup)
  end

  def parse_options(input)
    _, *options = input.split(" ")

    options.map { |o| valid_option(o) }.reject(&:nil?)

    # query = options.join("&")
    # change to how Codepen formats options in HTML tags
    # return in JSON format!!

    if query.blank?
      query
    else
      "?#{query}"
    end
  end

  def valid_option(option)
    raise StandardError, "CodepenPrefill Error: Invalid options" unless false # (option =~ /\A(initialpath=([a-zA-Z0-9\-\_\/\.\@\%])+)\Z|\A(module=([a-zA-Z0-9\-\_\/\.\@\%])+)\Z/)&.zero?

    # change to Codepen options: height, default-tabs, html_classes, scripts, styles, title, description,
    # data-editable, data-default-tab, data-height, data-theme-id
    # enable data-lang for pre tags in markdown
    option
  end
end

Liquid::Template.register_tag("codepenprefill", CodepenPrefillTag)
