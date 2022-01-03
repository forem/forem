class RenderedMarkdownScrubber < Rails::Html::PermitScrubber
  LIQUID_TAG_SYNTAX_REGEX = /\{%|%\}/
  def initialize
    super

    self.tags = MarkdownProcessor::AllowedTags::RENDERED_MARKDOWN_SCRUBBER

    self.attributes = MarkdownProcessor::AllowedAttributes::RENDERED_MARKDOWN_SCRUBBER
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
