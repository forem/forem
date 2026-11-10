module CommentsHelper
  MAX_COMMENTS_TO_RENDER = 250
  MIN_COMMENTS_TO_RENDER = 8
  MAX_TOP_LEVEL_COMMENTS_UNAUTHENTICATED = 75
  MAX_DESCENDANT_COMMENTS_UNAUTHENTICATED = 5

  def any_negative_comments?(commentable)
    return false if no_comments_on?(commentable)

    if commentable.instance_variable_defined?(:@any_negative_comments)
      return commentable.instance_variable_get(:@any_negative_comments)
    end

    target = commentable.respond_to?(:object) ? commentable.object : commentable
    if target.instance_variable_defined?(:@any_negative_comments)
      return target.instance_variable_get(:@any_negative_comments)
    end
    return commentable.comments.any? { |comment| comment.score.to_i.negative? } if commentable.comments.loaded?

    has_negative = commentable.comments.where("score < 0").any?
    target.instance_variable_set(:@any_negative_comments, has_negative) unless target.frozen?
    has_negative
  end

  def any_hidden_negative_comments?(commentable)
    !user_signed_in? && any_negative_comments?(commentable)
  end

  def all_comments_visible?(commentable)
    !(commentable.any_comments_hidden || any_hidden_negative_comments?(commentable))
  end

  def article_comment_tree(article, limit, order)
    article.comment_tree(limit: limit, order: order, include_negative: user_signed_in?)
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

  ORG_MEMBER_ROLES = %w[admin member].freeze

  def commenter_organization_membership(comment, commentable)
    return unless commentable.respond_to?(:organization)
    return unless commentable.organization

    # Use preloaded organization_memberships if available to avoid N+1 queries
    if comment.user.organization_memberships.loaded?
      has_membership = comment.user.organization_memberships.any? do |membership|
        membership.organization_id == commentable.organization.id &&
          ORG_MEMBER_ROLES.include?(membership.type_of_user)
      end
      has_membership ? commentable.organization.name : nil
    else
      # Fallback to the original method if not preloaded
      comment.user.org_member?(commentable.organization) ? commentable.organization.name : nil
    end
  end

  def nested_comments(tree:, commentable:, is_view_root: false, is_admin: false)
    return "".html_safe if tree.blank?

    native_nested_comments(tree: tree, commentable: commentable, is_view_root: is_view_root, is_admin: is_admin) ||
      legacy_nested_comments(tree: tree, commentable: commentable, is_view_root: is_view_root, is_admin: is_admin)
  end

  private

  def no_comments_on?(commentable)
    return false unless commentable.respond_to?(:comments_count)

    commentable.comments_count.to_i <= 0 &&
      (!commentable.respond_to?(:displayed_comments_count) || commentable.displayed_comments_count.to_i <= 0)
  end

  def limit_descendants(sub_hash, limit)
    count = 0
    traverse = lambda do |hash|
      new_hash = {}
      hash.each do |c, children|
        break if count >= limit

        count += 1
        new_hash[c] = traverse.call(children)
      end
      new_hash
    end
    traverse.call(sub_hash)
  end

  def legacy_nested_comments(tree:, commentable:, is_view_root: false, is_admin: false)
    comments = tree.filter_map do |comment, sub_comments|
      subtree_html = legacy_nested_comments(tree: sub_comments, commentable: commentable, is_admin: is_admin)
      is_childless = subtree_html.blank?
      # hide childless comments if they are low quality or soft-deleted (but show for admins)
      hide = is_childless && (comment.decorate.super_low_quality || comment.deleted?)
      if is_admin || !hide
        render("comments/comment", comment: comment, commentable: commentable,
                                   is_view_root: is_view_root, is_childless: is_childless,
                                   is_admin: is_admin,
                                   subtree_html: subtree_html)
      end
    end
    safe_join(comments)
  end

  # rubocop:disable Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Rails/HelperInstanceVariable, Rails/OutputSafety
  def native_nested_comments(tree:, commentable:, is_view_root: false, is_admin: false)
    return unless defined?(ForemNative) && ForemNative.respond_to?(:render_comment_tree)

    authors_buf = (@_comment_tree_authors_buf ||= [])
    nodes_buf = (@_comment_tree_nodes_buf ||= [])
    view_buf = (@_comment_tree_view_buf ||= [])
    authors_buf.clear
    nodes_buf.clear
    view_buf.clear

    author_indices = {}.compare_by_identity
    has_deleted_comment = false
    staff_user = User.staff_account
    header_field_defs = nil

    pack_tree = lambda do |branch|
      return false unless branch.is_a?(Hash)

      branch.each do |comment, sub_comments|
        return false unless comment.is_a?(Comment)

        user = comment.user
        return false unless user.is_a?(User)
        if comment.association(:commentable).loaded? && comment.commentable && comment.commentable != commentable
          return false
        end

        sub_hash = sub_comments || {}
        return false unless sub_hash.is_a?(Hash)

        author_idx = author_indices[user]
        unless author_idx
          author_idx = author_indices.size
          author_indices[user] = author_idx

          user_url = URL.user(user)
          return false unless user_url.is_a?(String)

          setting = user.setting
          profile = user.profile
          return false unless setting && profile

          brand_hex = setting.brand_color1
          if brand_hex.blank?
            assigned = UserDecorator::ASSIGNED_COLORS[(user.id || 0) % 10]
            bg_hex = assigned[:bg]
            text_hex = assigned[:text]
          else
            bg_hex = brand_hex
            text_hex = "#ffffff"
          end
          smallest_hex = [bg_hex, text_hex].min
          card_color_fallback = if ForemNative.color_brightness(smallest_hex, 0.88, only_values: false).nil?
                                  Color::CompareHex.new([bg_hex, text_hex]).brightness(0.88).to_s
                                end

          header_fields_flat = nil
          if profile.data.present?
            header_field_defs ||= ProfileField.cached_display_area_fields(:header)
            ui_attrs = header_field_defs.transform_values { |attr_name| profile.data[attr_name] }.compact_blank
            if ui_attrs.present?
              header_fields_flat = []
              ui_attrs.sort.each do |title, value|
                header_fields_flat.push(
                  t("views.users.profile_fields.#{title.downcase}", default: title.titleize).to_s,
                  value.to_s,
                )
              end
            end
          end

          u_ca = user.created_at
          org_name = commenter_organization_membership(comment, commentable)
          is_op = !commentable_author_is_op?(commentable, comment).nil? &&
            commentable_author_is_op?(commentable, comment) != false
          by_staff = staff_user ? (user == staff_user) : false
          is_sub = user.respond_to?(:cached_base_subscriber?) && user.cached_base_subscriber?
          is_leader = user.try(:cached_community_leader?) ? true : false
          tag_line = user.tag_line.presence
          disp_email = setting.display_email_on_profile ? user.email.to_s : nil
          loc = profile.location.presence

          authors_buf.push(
            user.id,
            user.name.to_s,
            user.username.to_s,
            user_url,
            user.profile_image_url_for(length: 50).to_s,
            user.profile_image_url_for(length: 90).to_s,
            org_name&.to_s,
            is_op,
            by_staff,
            is_sub ? true : false,
            is_leader,
            smallest_hex,
            card_color_fallback,
            tag_line&.to_s,
            disp_email,
            loc&.to_s,
            header_fields_flat,
            u_ca&.tv_sec,
            u_ca ? u_ca.utc_offset : 0,
          )
        end

        deleted = comment.deleted ? true : false
        has_deleted_comment = true if deleted

        raw_html = comment.processed_html.to_s
        html_for_node = if raw_html.include?("runkit-element")
                          comment.__send__(:replace_legacy_code_html, raw_html)
                        else
                          raw_html
                        end

        raw_ai = comment.ai_disclosure_level_before_type_cast
        ai_level = case raw_ai
                   when Integer then raw_ai
                   when "some_ai", :some_ai then 3
                   when "fully_autonomous", :fully_autonomous then 5
                   when "no_ai", :no_ai then 1
                   else 0
                   end

        c_ca = comment.created_at
        return false if c_ca.nil? && !deleted

        c_ea = comment.edited_at

        nodes_buf.push(
          comment.id,
          author_idx,
          comment.ancestry,
          nil,
          false,
          comment.score.to_i,
          deleted,
          comment.hidden_by_commentable_user ? true : false,
          @root_comment ? (comment == @root_comment) : false,
          comment.public_reactions_count.to_i,
          comment.favorited_by_user_id,
          comment.id_code.to_s,
          html_for_node,
          ai_level,
          c_ca&.tv_sec,
          c_ca ? c_ca.utc_offset : 0,
          c_ea&.tv_sec,
          c_ea ? c_ea.utc_offset : 0,
          sub_hash.size,
        )

        return false if !sub_hash.empty? && !pack_tree.call(sub_hash)
      end
      true
    end

    return unless pack_tree.call(tree)

    static_ctx = comment_tree_static_context
    return unless static_ctx

    app_base_url = URL.url(nil)
    comment_domain = unless Subforem.disabled_by_env?
                       subforem_id = if commentable.instance_of?(::Article) && commentable.respond_to?(:subforem_id)
                                       commentable.subforem_id || RequestStore.store[:default_subforem_id]
                                     else
                                       RequestStore.store[:subforem_id]
                                     end
                       Subforem.cached_id_to_domain_hash[subforem_id] if subforem_id
                     end
    comment_base_url = URL.url(nil, comment_domain)

    warden_missing = !respond_to?(:request) || request.nil? || request.env.nil? || request.env["warden"].nil?
    signed_in = !warden_missing && respond_to?(:user_signed_in?) && user_signed_in?
    article_path_str = @article&.path
    contextual_use_permalink = warden_missing || signed_in || article_path_str.nil?

    mascot_html = if has_deleted_comment
                    image_tag(
                      Images::Optimizer.call(Settings::General.mascot_image_url, width: 32, height: 32),
                      class: "crayons-avatar__image overflow-hidden",
                      alt: "Sloan, the sloth mascot",
                      loading: "lazy",
                    ).to_s
                  else
                    ""
                  end

    billboard_url = if @current_comment_index.present? && !@shown_billboard
                      billboard_async_path(:post_comments_mid, article: @article).to_s
                    else
                      ""
                    end

    ama_banner = commentable ? get_ama_or_op_banner(commentable).to_s : ""

    view_buf.push(
      !commentable.nil?,
      commentable&.path.to_s,
      commentable&.user_id.to_s,
      ama_banner,
      app_base_url,
      comment_base_url,
      contextual_use_permalink ? true : false,
      article_path_str&.to_s,
      mascot_html,
      billboard_url,
      !@root_comment.nil?,
      @root_comment&.hidden_by_commentable_user ? true : false,
      @discussion_lock ? true : false,
      is_admin ? true : false,
      is_view_root ? true : false,
      Time.current.year,
      @current_comment_index&.to_i,
      @shown_billboard ? true : false,
    )

    result = ForemNative.render_comment_tree(static_ctx, view_buf, authors_buf, nodes_buf, tree.size)
    return unless result

    html, updated_index, updated_shown_billboard = result
    @current_comment_index = updated_index if @current_comment_index.present?
    @shown_billboard = true if updated_shown_billboard
    html.html_safe
  rescue StandardError
    nil
  end

  def comment_tree_static_context
    fav_enabled = FeatureFlag.enabled?(:community_favorites)
    sub_enabled = FeatureFlag.enabled?("subscriber_icon")
    prior_cf = ApplicationConfig["PRIOR_CLOUDFLARE_IMAGES_DOMAIN"].presence
    current_cf = ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"].presence
    rng_loc = InlineSvg::IdGenerator::Randomness.method(:call).source_location
    cache_key = [I18n.locale, fav_enabled ? true : false, sub_enabled ? true : false, prior_cf, current_cf, rng_loc]

    if @_comment_tree_static_key == cache_key && @_comment_tree_static_ctx
      return @_comment_tree_static_ctx
    end

    abbr_months = I18n.t("date.abbr_month_names")
    return unless abbr_months.is_a?(Array) && abbr_months.size >= 13

    months_12 = abbr_months[1, 12].map(&:to_s)
    return unless months_12.size == 12

    if fav_enabled
      fav_label = t("favorites.favorited")
      fav_static_attrs = tag.attributes(
        data: {
          label_favorite: t("favorites.favorite"),
          label_favorited: fav_label,
          label_favorited_by_you: t("favorites.favorited_by_you"),
          confirm_title: t("favorites.confirm.title_comment"),
          confirm_body: t("favorites.confirm.body_comment"),
          confirm_submit: t("favorites.confirm.submit"),
          confirm_cancel: t("favorites.confirm.cancel"),
          modal_title: t("favorites.modal.title"),
          modal_body: t("favorites.modal.body"),
          modal_remaining_zero: t("favorites.modal.remaining_zero"),
          modal_remaining_one: t("favorites.modal.remaining_one"),
          modal_remaining_other: t("favorites.modal.remaining_other"),
          modal_remaining_unlimited: t("favorites.modal.remaining_unlimited"),
          modal_close: t("favorites.modal.close"),
          modal_exhausted_title: t("favorites.modal_exhausted.title"),
          modal_exhausted_body: t("favorites.modal_exhausted.body"),
          modal_exhausted_close: t("favorites.modal_exhausted.close")
        },
      ).to_s
      fav_inner_html = tag.span(
        class: "crayons-btn crayons-btn--ghost crayons-btn--s crayons-btn--icon " \
               "favorite-control favorite-control--favorited crayons-tooltip__activator relative",
        role: "img",
        aria: { label: fav_label },
      ) do
        concat crayons_icon_tag("small-favorite-filled", native: true)
        concat tag.span(fav_label, data: { testid: "tooltip" }, class: "crayons-tooltip__content")
      end.to_s
    else
      fav_static_attrs = ""
      fav_inner_html = ""
    end

    sub_icon_html = if sub_enabled
                      link_to(
                        image_tag("subscription-icon.png", alt: "Subscriber", class: "subscription-icon"),
                        "/++",
                        style: "display: inline;",
                      ).to_s
                    else
                      ""
                    end
    sub_icon_no_link_html = if sub_enabled
                              image_tag("subscription-icon.png", class: "subscription-icon").to_s
                            else
                              ""
                            end
    leader_icon_html = if fav_enabled
                         image_tag(
                           "community-leader-icon.svg",
                           alt: t("views.leadership.icon.leader_alt"),
                           class: "community-leader-icon",
                         ).to_s
                       else
                         ""
                       end

    user_ph = "__FOREM_USER__"
    unhide_action = I18n.t("views.comments.menu.action.unhide")
    hide_action = I18n.t("views.comments.menu.action.hide")
    heart_icon_title = t("views.comments.footer.heart.icon")

    ctx = [
      crayons_icon_tag(:collapse, class: "expanded", title: t("views.comments.collapse")).to_s,
      crayons_icon_tag(:expand, class: "collapsed", title: t("views.comments.expand")).to_s,
      crayons_icon_tag(:info, class: "mr-2", title: t("views.comments.quality.hidden.icon")).to_s,
      crayons_icon_tag("small-medal").to_s,
      crayons_icon_tag(
        "small-overflow-horizontal",
        class: "pointer-events-none",
        title: t("views.comments.menu.icon"),
      ).to_s,
      crayons_icon_tag("small-heart", class: "reaction-icon not-reacted", title: heart_icon_title).to_s,
      crayons_icon_tag(
        "small-heart-filled",
        class: "crayons-icon reaction-icon--like reaction-icon reacted",
        title: heart_icon_title,
      ).to_s,
      crayons_icon_tag(
        "small-comment",
        class: "reaction-icon not-reacted",
        title: t("views.comments.footer.reply.icon"),
      ).to_s,
      crayons_icon_tag("small-thread", title: t("views.comments.footer.thread.icon")).to_s,
      sub_icon_html,
      sub_icon_no_link_html,
      leader_icon_html,
      fav_enabled ? true : false,
      fav_static_attrs,
      fav_inner_html,
      t("views.comments.delete.comment_deleted").to_s,
      t("views.comments.hidden.comment_hidden").to_s,
      t("views.comments.quality.low").to_s,
      t("views.comments.quality.conduct").to_s,
      t("views.comments.quality.superlow").to_s,
      t("views.comments.quality.hidden.text.visible_in_permalink").to_s,
      t("views.comments.quality.hidden.text.accessible_via_permalink").to_s,
      I18n.t("views.users.details", user: user_ph).to_s,
      t("views.comments.edited.text_html", date: "__FOREM_DATE__".html_safe).to_s,
      t("views.comments.edited.short_html").to_s,
      t("views.comments.ai_disclosure.some_ai_description").to_s,
      I18n.t("models.comment.ai_disclosure.some_ai").to_s,
      t("views.comments.ai_disclosure.fully_autonomous_description").to_s,
      I18n.t("models.comment.ai_disclosure.fully_autonomous").to_s,
      t("views.comments.menu.aria_label").to_s,
      I18n.t("views.comments.menu.copy.aria_label", user: user_ph).to_s,
      t("views.comments.menu.copy.text").to_s,
      I18n.t("views.comments.menu.settings.aria_label", user: user_ph).to_s,
      I18n.t("views.comments.menu.action.aria_label", action: unhide_action, user: user_ph).to_s,
      t("views.comments.menu.action.unhide_text").to_s,
      I18n.t("views.comments.menu.action.aria_label", action: hide_action, user: user_ph).to_s,
      t("views.comments.menu.action.hide_text").to_s,
      t("views.comments.menu.admin_profile.text").to_s,
      I18n.t("views.comments.menu.admin_profile.aria_label", user: user_ph).to_s,
      I18n.t("views.comments.menu.moderate.aria_label", user: user_ph).to_s,
      I18n.t("views.comments.menu.report.aria_label", user: user_ph).to_s,
      t("views.comments.footer.heart.aria_label").to_s,
      t(
        "views.comments.footer.heart.count_html",
        num: "__FOREM_NUM__".html_safe,
        likes: "__FOREM_LIKES__".html_safe,
      ).to_s,
      I18n.t("helpers.comments_helper.nbsp_likes_html", count: 1).to_s.sub(/\b1\b/, "__FOREM_COUNT__"),
      I18n.t("helpers.comments_helper.nbsp_likes_html", count: 999_999).to_s.sub("999999", "__FOREM_COUNT__"),
      t("views.comments.footer.heart.title").to_s,
      t("views.comments.footer.reply.text").to_s,
      t("views.comments.footer.thread.text").to_s,
      I18n.t(
        "helpers.application_helper.follow.text.User",
        default: I18n.t("helpers.application_helper.follow.text.default"),
      ).to_s,
      I18n.t("helpers.application_helper.follow.aria_label.User",
             name: user_ph,
             default: I18n.t("helpers.application_helper.follow.aria_label.default", type: "User", name: user_ph)).to_s,
      t("views.sticky.email").to_s,
      t("views.sticky.location").to_s,
      t("views.sticky.joined").to_s,
      I18n.t("time.formats.short").to_s,
      I18n.t("time.formats.short_with_yy").to_s,
      I18n.t("time.formats.short_with_year").to_s,
      months_12,
      prior_cf,
      current_cf,
    ]

    @_comment_tree_static_key = cache_key
    @_comment_tree_static_ctx = ctx
  end
  # rubocop:enable Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Rails/HelperInstanceVariable, Rails/OutputSafety
end
