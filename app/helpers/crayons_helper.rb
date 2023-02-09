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

    inline_svg_tag(icon_name, aria: true, class: icon_class, **opts)
  end
end
