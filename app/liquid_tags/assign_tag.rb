class AssignTag < Liquid::Block
  def initialize(_tag_name, _markup, _options)
    raise StandardError.new("Liquid's Assign tag is disabled")
  end
end

Liquid::Template.register_tag("assign".freeze, AssignTag)
