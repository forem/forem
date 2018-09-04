class CycleTag < Liquid::Block
  def initialize(_tag_name, _markup, _options)
    raise StandardError.new("Liquid's Cycle tag is disabled")
  end
end

Liquid::Template.register_tag("cycle".freeze, CycleTag)
