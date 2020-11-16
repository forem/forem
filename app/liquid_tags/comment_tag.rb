class CommentTag < LiquidTagBase
  PARTIAL = "comments/liquid".freeze

  def initialize(_tag_name, id_code, _parse_context)
    super
    @comment = find_comment(id_code.strip)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { comment: @comment },
    )
  end

  def find_comment(id_code)
    Comment.find_by(id_code: id_code)
  end
end

Liquid::Template.register_tag("comment", CommentTag)
# kept for compatibility with existing comments embeds on DEV
Liquid::Template.register_tag("devcomment", CommentTag)
