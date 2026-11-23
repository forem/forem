class SvgIconScrubber < Loofah::Scrubber
  ALLOWED_TAGS = %w[
    svg g defs clipPath mask symbol
    path circle ellipse rect line polyline polygon
    linearGradient radialGradient stop
    title desc
    filter feBlend feColorMatrix feComposite feFlood feGaussianBlur feMerge feMergeNode feOffset
  ].to_set.freeze

  ALLOWED_ATTRIBUTES = %w[
    xmlns version viewBox width height x y x1 y1 x2 y2 cx cy r rx ry dx dy fx fy fr
    d points pathLength transform preserveAspectRatio
    fill fill-opacity fill-rule stroke stroke-dasharray stroke-dashoffset
    stroke-linecap stroke-linejoin stroke-miterlimit stroke-opacity stroke-width
    opacity color stop-color stop-opacity flood-color flood-opacity
    clip-path clip-rule clipPathUnits mask maskUnits maskContentUnits
    filter filterUnits gradientUnits gradientTransform spreadMethod
    offset in in2 mode operator result stdDeviation values color-interpolation-filters
    id class role aria-hidden aria-label aria-labelledby focusable
    shape-rendering image-rendering text-rendering vector-effect
  ].to_set.freeze

  DISALLOWED_ATTRIBUTE_NAMES = %w[
    href xlink:href src style formaction action srcdoc srcset ping dynsrc lowsrc
    xml:base data-action data-controller
  ].to_set.freeze

  SVG_NAMESPACE = "http://www.w3.org/2000/svg".freeze
  LOCAL_URL_REF_REGEXP = /\Aurl\(\s*['"]?#[\w\-.:]+['"]?\s*\)\z/i
  DISALLOWED_URI_REGEXP = /\b(?:javascript|vbscript|data)\s*:/i
  EVENT_HANDLER_REGEXP = /\Aon/i
  DISALLOWED_URI_CHARS_REGEXP = /[\x00-\x20\uFFFD]+/

  def self.sanitize(svg)
    return "" if svg.blank?

    fragment = Loofah.html5_fragment(svg.to_s)
    fragment.children.each do |child|
      child.remove unless child.element? && child.name == "svg"
    end
    fragment.scrub!(new)
    fragment.to_html.strip
  end

  def self.valid_svg?(svg)
    return false if svg.blank?

    fragment = Loofah.html5_fragment(svg.to_s)
    element_children = fragment.children.select(&:element?)
    return false unless element_children.size == 1 && element_children.first.name == "svg"
    return false if fragment.children.any? { |child| child.text? && child.text.strip.present? }

    valid_subtree?(element_children.first)
  end

  def self.valid_subtree?(root)
    root.traverse do |node|
      return false if node.cdata? || node.processing_instruction?
      next unless node.element?
      return false unless ALLOWED_TAGS.include?(node.name)
      return false unless valid_node_attributes?(node)
    end
    true
  end
  private_class_method :valid_subtree?

  def self.valid_node_attributes?(node)
    node.attribute_nodes.all? do |attr|
      name = qualified_attribute_name(attr)
      next false if name.match?(EVENT_HANDLER_REGEXP)
      next false if DISALLOWED_ATTRIBUTE_NAMES.include?(name) || name.start_with?("xlink:")

      safe_attribute_value?(name, attr.value)
    end
  end
  private_class_method :valid_node_attributes?

  def self.qualified_attribute_name(attr)
    prefix = attr.namespace&.prefix
    prefix ? "#{prefix}:#{attr.name}".downcase : attr.name.downcase
  end
  private_class_method :qualified_attribute_name

  def self.safe_attribute_value?(name, value)
    normalized = value.to_s.strip
    return normalized == SVG_NAMESPACE if name == "xmlns"

    compact = normalized.gsub(DISALLOWED_URI_CHARS_REGEXP, "")
    return false if compact.match?(DISALLOWED_URI_REGEXP)
    return normalized.match?(LOCAL_URL_REF_REGEXP) if compact.match?(/url\(/i)

    true
  end

  def initialize
    super
    @direction = :top_down
  end

  def scrub(node)
    if node.comment? || node.cdata? || node.processing_instruction?
      node.remove
      return STOP
    end

    return CONTINUE unless node.element?

    unless ALLOWED_TAGS.include?(node.name)
      node.remove
      return STOP
    end

    scrub_attributes(node)
    CONTINUE
  end

  private

  def scrub_attributes(node)
    node.attribute_nodes.each do |attr|
      name = attr.name
      if ALLOWED_ATTRIBUTES.exclude?(name) || !self.class.safe_attribute_value?(name.downcase, attr.value)
        attr.remove
      end
    end
  end
end
