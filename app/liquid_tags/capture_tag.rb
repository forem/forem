class CaptureTag < Liquid::Block
  def initialize(_tag_name, _markup, _options)
    raise StandardError.new("Liquid's Capture tag is disabled")
  end
end

Liquid::Template.register_tag("capture".freeze, CaptureTag)
