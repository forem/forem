module CrayonsHelper
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

    key = [icon_name, icon_class, opts]
    svg = ICON_CACHE[key] || begin
      ICON_CACHE.clear if ICON_CACHE.size >= ICON_CACHE_LIMIT
      ICON_CACHE[key] = String.new(inline_svg_tag(icon_name, aria: true, class: icon_class, **opts)).freeze
    end
    with_fresh_aria_ids(svg).html_safe # rubocop:disable Rails/OutputSafety
  end

  # inline_svg re-serializes and re-parses the whole SVG once per transformation (title, aria,
  # class, width, height), which costs about half a millisecond per icon. The output only depends
  # on the arguments, so it is rendered once per process and reused. The keyspace is bounded by a
  # simple size cap because a few icons carry record-specific titles.
  ICON_CACHE = Concurrent::Map.new
  ICON_CACHE_LIMIT = 2_000
  ARIA_LABELLEDBY = /\A<svg\b[^>]*?\baria-labelledby="([^"]+)"/

  private

  # inline_svg gives every <title>/<desc> a random id per render so the aria-labelledby
  # references on a page stay unique. Re-randomize them on each call to keep that guarantee.
  def with_fresh_aria_ids(svg)
    ids = svg[ARIA_LABELLEDBY, 1]&.split
    return svg if ids.blank?

    fresh_ids = ids.index_with { |id| InlineSvg::IdGenerator.generate("aria", id) }
    svg.gsub(Regexp.union(ids), fresh_ids)
  end
end
