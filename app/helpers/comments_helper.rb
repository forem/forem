module CommentsHelper
  MAX_COMMENTS_TO_RENDER = 250
  MIN_COMMENTS_TO_RENDER = 8

  def any_negative_comments?(commentable)
    commentable.comments.where("score < 0").any?
  end

  def any_hidden_negative_comments?(commentable)
    !user_signed_in? && any_negative_comments?(commentable)
  end

  def all_comments_visible?(commentable)
    !(commentable.any_comments_hidden || any_hidden_negative_comments?(commentable))
  end

  def article_comment_tree(article, limit, order)
    Comments::Tree.for_commentable(article, limit: limit, order: order, include_negative: user_signed_in?)
  end

  def podcast_comment_tree(episode)
    Comments::Tree.for_commentable(episode, include_negative: user_signed_in?, limit: 12)
  end

  def comment_class(comment, is_view_root: false)
    if comment.root? || is_view_root
      "root"
    else
      "child"
    end
  end

  def comment_user_id_unless_deleted(comment)
    comment.deleted ? 0 : comment.user_id
  end

  def commentable_author_is_op?(commentable, comment)
    commentable &&
      [
        commentable.user_id,
        commentable.co_author_ids,
      ].flatten.any?(comment.user_id)
  end

  def get_ama_or_op_banner(commentable)
    if commentable.decorate.cached_tag_list_array.include?(I18n.t("helpers.comments_helper.ama"))
      I18n.t("helpers.comments_helper.ask_me_anything")
    else
      I18n.t("helpers.comments_helper.author")
    end
  end

  def should_be_hidden?(comment, root_comment)
    # when opened by a permalink + root comment is hidden => show root comment and its descendants
    comment.hidden_by_commentable_user && comment != root_comment && !root_comment&.hidden_by_commentable_user
  end

  def high_number_of_comments?(comments_number)
    comments_number > MAX_COMMENTS_TO_RENDER
  end

  def view_all_comments?(comments_number)
    comments_number > MIN_COMMENTS_TO_RENDER
  end

  def number_of_comments_to_render
    MAX_COMMENTS_TO_RENDER
  end

  def comment_count(view)
    view == "comments" ? MAX_COMMENTS_TO_RENDER : MIN_COMMENTS_TO_RENDER
  end

  def like_button_text(comment)
    # TODO: [yheuhtozr] support cross-element i18n compatible with initializeCommentsPage.js.erb
    if comment.public_reactions_count.zero?
      ""
    else
      I18n.t("helpers.comments_helper.nbsp_likes_html", count: comment.public_reactions_count)
    end
  end

  def contextual_comment_url(comment, article: nil)
    # Liquid tag parsing doesn't have Devise/Warden (request middleware)
    return URL.comment(comment) if request.env["warden"].nil?

    # Logged in users should get the comment permalink
    return URL.comment(comment) if user_signed_in?

    # Logged out users should get the article URL with the comment anchor
    URL.fragment_comment(comment, path: article&.path)
  end

  def commenter_organization_membership(comment, commentable)
    return unless commentable&.respond_to?(:organization)
    return unless commentable.organization

    # Use preloaded organization_memberships if available to avoid N+1 queries
    if comment.user.organization_memberships.loaded?
      if comment.user.organization_memberships.any? do |membership|
        membership.organization_id == commentable.organization.id &&
            %w[admin member].include?(membership.type_of_user)
      end
        commentable.organization.name
      else
        nil
      end
    else
      # Fallback to the original method if not preloaded
      comment.user.org_member?(commentable.organization) ? commentable.organization.name : nil
    end
  end

  private

  def nested_comments(tree:, commentable:, is_view_root: false, is_admin: false)
    comments = tree.filter_map do |comment, sub_comments|
      is_childless = sub_comments.empty?
      # hide childless comments with score below hide threshold (but show for admins)
      hide = comment.decorate.super_low_quality && is_childless
      if is_admin || !hide
        render("comments/comment", comment: comment, commentable: commentable,
                                   is_view_root: is_view_root, is_childless: is_childless,
                                   is_admin: is_admin,
                                   subtree_html: nested_comments(tree: sub_comments,
                                                                 commentable: commentable,
                                                                 is_admin: is_admin))
      end
    end
    safe_join(comments)
  end
end
