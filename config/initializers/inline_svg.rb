require "unique_svg_transform"

InlineSvg.configure do |config|
  # NOTE: There is currently a bug in the inline_svg gem where custom attributes
  # are de-facto required in order for a custom transformation to be activated.
  config.add_custom_transformation attribute: :force_unique, transform: UniqueSvgTransform
end
