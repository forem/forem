class NullTag < Liquid::Block
  def initialize(_tag_name, _markup, _options)
    raise StandardError, "Liquid##{_tag_name} tag is disabled"
  end
end

disabled_tags = %w(assign capture case comment cycle for if ifchanged include unless)

disabled_tags.each do |tag|
  Liquid::Template.register_tag(tag, NullTag)
end
