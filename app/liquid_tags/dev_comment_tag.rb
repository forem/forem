class DevCommentTag < LiquidTagBase
  PARTIAL = "comments/liquid".freeze

  def initialize(_tag_name, id_code, _tokens)
    @id_code = id_code.strip
  end

  def render(_context)
    comment = find_comment

    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: { comment: comment },
    )
  end

  def render_twitter_and_github
    result = ""
    if @comment.user.twitter_username.present?
      result += "<a href=\"https://twitter.com/#{@comment.user.twitter_username}\">" \
        +image_tag("/assets/twitter-logo.svg", class: "icon-img", alt: "twitter") + \
        "</a>"
    end
    if @comment.user.github_username.present?
      result + "<a href=\"https://github.com/#{@comment.user.github_username}\">" \
        +image_tag("/assets/github-logo.svg", class: "icon-img", alt: "github") + \
        "</a>"
    end
  end

  private

  def find_comment
    Comment.find(@id_code.to_i(26))
  rescue ActiveRecord::RecordNotFound
    raise StandardError, "Invalid comment ID or comment does not exist"
  end
end

Liquid::Template.register_tag("devcomment", DevCommentTag)
