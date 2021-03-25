class RenderedMarkdownScrubber < Rails::Html::PermitScrubber
  def initialize
    super

    self.tags = %w[
      a abbr add aside b blockquote br button center cite code col colgroup dd del dl dt em em figcaption
      h1 h2 h3 h4 h5 h6 hr i img kbd li mark ol p pre q rp rt ruby small source span strong sub sup table
      tbody td tfoot th thead time tr u ul video
    ]

    self.attributes = %w[
      alt class colspan data-conversation data-lang data-no-instant data-url em height href id loop
      name ref rel rowspan size span src start strong title type value width controls
    ]
  end

  def allowed_node?(node)
    @tags.include?(node.name) || valid_codeblock_div?(node)
  end

  private

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
