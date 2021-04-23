class RenderedMarkdownScrubber < Rails::Html::PermitScrubber
  LIQUID_TAG_SYNTAX_REGEX = /\{%|%\}/.freeze
  def initialize
    super

    self.tags = %w[
      a abbr add b blockquote br button center cite code col colgroup dd del dl dt em figcaption
      h1 h2 h3 h4 h5 h6 hr img kbd li mark ol p pre q rp rt ruby small source span strong sub sup table
      tbody td tfoot th thead time tr u ul video
    ]

    self.attributes = %w[
      alt colspan data-conversation data-lang data-no-instant data-url href id loop
      name ref rel rowspan span src start title type value controls
    ]
  end

  def allowed_node?(node)
    @tags.include?(node.name) || valid_codeblock_div?(node)
  end

  # Overrides scrub_attributes in
  # https://github.com/rails/rails-html-sanitizer/blob/master/lib/rails/html/scrubbers.rb
  def scrub_attributes(node)
    # We only want to call super if we aren't in a codeblock
    # because the `class` attribute will be stripped
    if inside_codeblock?(node)
      node.attribute_nodes.each do |attr|
        scrub_attribute(node, attr)
      end

      scrub_css_attribute(node)
    else
      scrub_valid_attributes(node)
      super
    end
  end

  private

  def scrub_valid_attributes(node)
    node.attributes.each_value do |attribute|
      attribute.value = attribute.value.remove(LIQUID_TAG_SYNTAX_REGEX)
    end
  end

  def inside_codeblock?(node)
    node.attributes["class"]&.value&.include?("highlight") ||
      (node.name == "span" && node.ancestors.first.name == "code")
  end

  def valid_codeblock_div?(node)
    node.name == "div" &&
      node.attributes.count == 1 &&
      node.children.first&.name == "pre" &&
      node.parent.name == "#document-fragment" &&
      node.attributes.values.any? do |attribute_value|
        attribute_value.value == "highlight"
      end
  end
end
