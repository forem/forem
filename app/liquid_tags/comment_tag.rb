class CommentTag < Liquid::Block
  def initialize(_tag_name, _markup, _options)
    raise StandardError.new("Liquid's Comment tag is disabled")
  end
end

Liquid::Template.register_tag("Comment".freeze, CommentTag)
