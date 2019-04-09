class CodepenPrefillTag < Liquid::Block
  def initialize(tag_name, options, tokens)
    super
    @data = parse_data(options)
    @prefill = parse_prefill(options)
  end

  def render(context)
    content = Nokogiri::HTML(super)
    # parsed_content = content.xpath("//html/body").text # dont parse for text???
    html = <<~HTML
      <div
        class="codepen"
        data-prefill='#{@prefill}'
        #{@data}
        >
        #{content}
      </div>
      <script async src="https://static.codepen.io/assets/embed/ei.js"></script>
    HTML
    html
  end

  def parse_data(input)
    options = create_options(input)
    data_attr = ["editable", "default-tab", "height", "theme-id"].to_set

    data = ""
    options.each do |i|
      key = i.split("=")[0]
      next unless data_attr.include?(key)

      val = i.split("=")[1]
      val = validate_data_options(key, val)
      attr = "data-" + key + "=" + val
      data = attr + " " + data
    end

    data
  end

  def validate_data_options(key, val)
    if (key == "editable") && (val != false)
      val = "true"
    elsif (key == "height") && (val.to_i > 600)
      val = "600"
    end
    val
  end

  def parse_prefill(input)
    options = create_options(input)
    prefill_attr = %w[title description head tags html_classes stylesheets scripts].to_set

    prefill = {}
    options.each do |i|
      key = i.split("=")[0]
      next unless prefill_attr.include?(key)

      val = i.split("=")[1]
      val = split_multiple_options(key, val)
      prefill[key] = val
    end

    prefill.to_json
  end

  def split_multiple_options(_key, val)
    val = val.split(",") if val.include? ","
    val
  end

  def create_options(input)
    stripped_input = ActionController::Base.helpers.strip_tags(input)
    options = stripped_input.split(" ")
    options.map { |o| valid_option(o) }.reject(&:nil?)
    options
  end

  def valid_option(option)
    raise StandardError, "CodepenPrefill Error: Invalid options" unless option =~ /^[A-Za-z-]+={1}[\[\]]?["\w.,"]*[\[\]]?/

    option
  end
end

Liquid::Template.register_tag("codepenprefill", CodepenPrefillTag)
