class RenderedMarkdownScrubber < Rails::Html::PermitScrubber
  LIQUID_TAG_SYNTAX_REGEX = /\{%|%\}/
  TABLE_CELL_TAGS = %w[td th].freeze
  ALLOWED_TEXT_ALIGN = %w[left center right].freeze

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
      alignment = cell_text_align(node)
      scrub_valid_attributes(node)
      super
      node["style"] = "text-align: #{alignment}" if alignment
    end
  end

  private

  # Redcarpet emits `style="text-align: …"` on aligned table cells. `super`
  # strips all style, so the validated alignment keyword is re-applied here —
  # only on table cells, and only for the three text-align keywords.
  def cell_text_align(node)
    return unless TABLE_CELL_TAGS.include?(node.name)

    style = node["style"]
    return if style.blank?

    style.split(";").each do |declaration|
      property, value = declaration.split(":", 2)
      next if value.nil? || !property.strip.casecmp?("text-align")

      keyword = value.strip.downcase
      return keyword if ALLOWED_TEXT_ALIGN.include?(keyword)
    end

    nil
  end

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
