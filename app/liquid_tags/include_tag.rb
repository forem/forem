class IncludeTag < Liquid::Block
  def initialize(_tag_name, _markup, _options)
    raise StandardError.new("Liquid's Include tag is disabled")
  end
end

Liquid::Template.register_tag("include".freeze, IncludeTag)
