module CrayonsHelper
  # The +inline_svg_tag+ options ForemNative.inline_svg_icon applies itself.
  NATIVE_ICON_OPTIONS = %i[width height title aria_hidden].freeze
  # Icon name => the icon's SVG as Nokogiri serializes it, the starting point for every
  # +inline_svg_tag+ transformation. The configured asset file never changes after boot.
  CANONICAL_ICON_SVGS = Concurrent::Map.new

  # A wrapper for the +inline_svg_tag+ helper specifically for Crayons icons.
  #
  # @param name [String|Symbol] the icon name. The ".svg" file extension will
  #   be added automatically if missing.
  # @param native [Boolean] when set to +true+ the icon will not inherit its
  #   parent's color.
  # @param opts [Hash] additional keyword arguments (like e.g. +class+) to be passed
  #   through to the +inline_svg_tag+ helper.
  # @return [String] the SVG tag.
  #
  # @example Simplest form
  #   crayons_icon_tag(:twitter)
  #
  # @example Disabling color inheritance
  #   crayons_icon_tag("twemoji/heart", native: true)
  #
  # @example Specifying additional CSS classes
  #   crayons_icon_tag("twitter.svg", class: "pointer-events-none")
  #
  # @example Specifying additional kwards to be passed to +inline_svg_tag+
  #   crayons_icon_tag(:home, title: "Home")
  def crayons_icon_tag(name, native: false, **opts)
    name = name.to_s
    icon_name = name.ends_with?(".svg") ? name : "#{name}.svg"
    icon_class = [
      "crayons-icon",
      ("crayons-icon--default" if native),
      opts.delete(:class),
    ].compact.join(" ")

    opts[:width] ||= 24
    opts[:height] ||= 24

    native_crayons_icon_tag(icon_name, icon_class, opts) ||
      inline_svg_tag(icon_name, aria: true, class: icon_class, **opts)
  end

  private

  # Splices the transformations into the icon's serialized SVG with ForemNative instead of
  # re-parsing it with Nokogiri once per transformation, as +inline_svg_tag+ does.
  def native_crayons_icon_tag(icon_name, icon_class, opts)
    return unless (opts.keys - NATIVE_ICON_OPTIONS).empty? && InlineSvg.configuration.custom_transformations.empty?
    return unless (svg = canonical_icon_svg(icon_name))

    width, height, title, aria_hidden = opts.values_at(:width, :height, :title, :aria_hidden)
    width, height = [width, height].map { |size| size.is_a?(Integer) ? size.to_s : size }
    aria_hidden = aria_hidden.to_s if aria_hidden == true
    aria_hidden = nil if aria_hidden == false
    title_id = InlineSvg::IdGenerator.generate("title", title) if title.is_a?(String)

    # Escaped like inline_svg_tag's output, which it also marks html_safe.
    ForemNative.inline_svg_icon(svg, icon_class, width, height,
                                aria_hidden: aria_hidden, title: title, title_id: title_id)&.html_safe # rubocop:disable Rails/OutputSafety
  end

  def canonical_icon_svg(icon_name)
    CANONICAL_ICON_SVGS[icon_name] ||= begin
      document = Nokogiri::XML::Document.parse(InlineSvg.configuration.asset_file.named(icon_name))
      InlineSvg::TransformPipeline::Transformations::NullTransformation.new(nil).with_svg(document).to_html
    end
  rescue InlineSvg::AssetFile::FileNotFound
    nil
  end
end
