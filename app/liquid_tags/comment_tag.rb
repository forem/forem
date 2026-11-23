class CommentTag < LiquidTagBase
  PARTIAL = "comments/liquid".freeze
  VALID_DOMAINS = -> { ([Settings::General.app_domain] + Subforem.cached_domains).compact.uniq }
  VALID_LINK_REGEXP = %r{https?://(?<domain>[^/]+)/\w+/comment/(?<comment_id>\w+)}
  VALID_ID_REGEXP = /\A(?<comment_id>\w+)\Z/
  REGEXP_OPTIONS = [VALID_LINK_REGEXP, VALID_ID_REGEXP].freeze

  def initialize(_tag_name, id_code, _parse_context)
    super

    input    = CGI.unescape_html(strip_tags(id_code))
    @comment = find_comment(parse_id_code(input))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { comment: @comment },
    )
  end

  def find_comment(id_code)
    comment = Comment.find_by(id_code: id_code)
    return unless visible_comment?(comment)

    comment
  end

  private

  def visible_comment?(comment)
    return false unless comment
    return false if comment.deleted? || comment.hidden_by_commentable_user?
    return false if comment.score.to_i < Comment::HIDE_THRESHOLD

    commentable_visible?(comment.commentable)
  end

  def commentable_visible?(commentable)
    case commentable
    when Article
      commentable.published? && commentable.published_at.present? && !commentable.scheduled?
    when PodcastEpisode
      commentable.reachable? && commentable.podcast&.published? == true
    else
      false
    end
  end

  def parse_id_code(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.comment_tag.invalid_comment") unless match

    if match.names.include?("domain") && match[:domain]
      raise StandardError, I18n.t("liquid_tags.comment_tag.invalid_comment") unless VALID_DOMAINS.call.include?(match[:domain])
    end

    match[:comment_id]
  end
end

Liquid::Template.register_tag("comment", CommentTag)
# kept for compatibility with existing comments embeds on DEV
Liquid::Template.register_tag("devcomment", CommentTag)
