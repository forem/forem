module CrayonsHelper
  # A wrapper for the +inline_svg_tag+ helper specifically for Crayons icons.
  #
  # @param name [String|Symbol] the icon name. The ".svg" file extension will
  #   be added automatically if missing.
  # @param css_class [String] additional CSS classes, "crayons-icon" is always
  #   included.
  # @param native [Boolean] when set to +true+ the icon will not inherit its
  #   parent's color.
  # @param **opts additional keyword arguments to be passed through to the
  #   +inline_svg_tag+ helper.
  # @return [String] the SVG tag.
  #
  # @example Simplest form
  #   crayons_icon_tag(:twitter)
  #
  # @example Disabling color inheritance
  #   crayons_icon_tag(:twitter, native: true)
  #
  # @example Specifying additional CSS classes
  #   crayons_icon_tag("twitter.svg", css_class: "pointer-events-none")
  def crayons_icon_tag(name, css_class: nil, native: false, **opts)
    name = name.to_s
    icon_name = name.ends_with?(".svg") ? name : "#{name}.svg"
    icon_class = [
      "crayons-icon",
      css_class,
      ("crayons-icon--default" if native),
    ].compact.join(" ")

    inline_svg_tag(icon_name, aria: true, width: 24, height: 24, class: icon_class, **opts)
  end
end
