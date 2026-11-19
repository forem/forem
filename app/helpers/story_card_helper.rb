module StoryCardHelper
  COUNT_SENTINEL = 999_999
  COUNT_PLACEHOLDER = "__FOREM_COUNT__".freeze
  USER_PLACEHOLDER = "__FOREM_USER__".freeze
  ORG_PLACEHOLDER = "__FOREM_ORG__".freeze
  TITLE_PLACEHOLDER = "__FOREM_TITLE__".freeze

  private_constant :COUNT_SENTINEL, :COUNT_PLACEHOLDER, :USER_PLACEHOLDER, :ORG_PLACEHOLDER, :TITLE_PLACEHOLDER

  def render_story_card(story, **options)
    return "".html_safe if story.nil?

    native_render_story_cards([story], **options) || legacy_render_story_card(story, **options)
  end

  def render_story_cards(stories, **options)
    list = Array(stories).compact
    return "".html_safe if list.empty?

    native_render_story_cards(list, **options) || legacy_render_story_cards(list, **options)
  end

  private

  def truthy_bool(value)
    !(value.nil? || value == false)
  end

  def legacy_render_story_card(story, **options)
    card_locals = build_legacy_story_locals(story, options)
    render partial: "articles/single_story_legacy", locals: card_locals
  end

  def legacy_render_story_cards(stories, **options)
    rendered = stories.map do |story|
      legacy_render_story_card(story, **options)
    end
    safe_join(rendered)
  end

  def build_legacy_story_locals(story, options)
    featured = resolve_story_flag(story, options, :featured, :featured_for, :featured_ids)
    pinned = resolve_story_flag(story, options, :pinned, :pinned_for, :pinned_ids)
    decorated_story = story.is_a?(Article) ? story.decorate : story
    locals = options.except(:featured_for, :featured_ids, :pinned_for, :pinned_ids).merge(
      story: decorated_story,
      featured: featured,
    )
    locals[:pinned] = true if pinned
    locals[:pinned] = false if options[:pinned] == false && !pinned
    if !locals.key?(:feed_style_preference) && !respond_to?(:feed_style_preference)
      locals[:feed_style_preference] = Settings::UserExperience.feed_style
    end
    locals
  end

  def resolve_story_flag(story, options, bool_key, proc_key, ids_key)
    if options[proc_key]
      truthy_bool(options[proc_key].call(story))
    elsif options[ids_key]
      options[ids_key].include?(story.id)
    else
      options[bool_key] == true
    end
  end

  def cover_url_requires_ruby?(main_image, cover_mode_kind, cf_prefix)
    cover_mode_kind == 2 ||
      (cover_mode_kind.zero? && !Rails.env.development? && main_image.start_with?("https://res.cloudinary.com/")) ||
      (cover_mode_kind == 1 && (
        !main_image.ascii_only? || main_image.end_with?("w_1000/") || (cf_prefix && main_image.start_with?(cf_prefix))
      ))
  end

  def resolve_curation_picker(record, fav_uid, viewer_id)
    return [1, nil] if viewer_id && fav_uid == viewer_id

    picker = record.favorited_by_user
    picker.present? ? [2, picker.username.to_s] : [3, nil]
  end

  def collect_unique_story_tags(raw_tags, seen_tags, unique_tag_names)
    pos = 0
    len = raw_tags.bytesize
    while pos < len
      comma = raw_tags.byteindex(", ", pos)
      t_name = comma ? raw_tags.byteslice(pos, comma - pos) : raw_tags.byteslice(pos, len - pos)
      if !t_name.empty? && !seen_tags.key?(t_name)
        seen_tags[t_name] = true
        unique_tag_names << t_name
      end
      break unless comma

      pos = comma + 2
    end
  end

  def populate_story_tag_colors_buf(unique_tag_names, primary_hex, batch_preload, tag_colors_buf)
    return if unique_tag_names.empty?

    cache_map = preloaded_tag_colors
    if batch_preload
      missing = unique_tag_names.reject { |t_name| cache_map.key?(t_name) }
      preload_tag_color_names(missing, cache_map) if missing.any?
    end
    unique_tag_names.each do |t_name|
      colors = cache_map[t_name] || tag_colors(t_name)
      bg_hex = colors[:background].presence || primary_hex
      tag_colors_buf.push(t_name, bg_hex.to_s)
    end
  end

  def preload_tag_color_names(tag_names, cache_map)
    names_by_key = tag_names.index_by { |tag_name| tag_colors_cache_key(tag_name) }
    missing_colors = nil
    colors_by_key = Rails.cache.fetch_multi(*names_by_key.keys, expires_in: 5.hours) do |key|
      missing_colors ||= find_tag_colors_by_name(tag_names)
      missing_colors[names_by_key[key]]
    end
    colors_by_key.each { |key, colors| cache_map[names_by_key[key]] = colors }
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Rails/HelperInstanceVariable, Rails/OutputSafety
  def native_render_story_cards(stories, **options)
    return unless defined?(ForemNative) && ForemNative.respond_to?(:render_story_cards)
    return if (respond_to?(:request) && request&.script_name.present?) ||
      (respond_to?(:url_options) && url_options[:script_name].present?)

    static_ctx = story_card_static_context
    return unless static_ctx

    authors_buf = (@_story_card_authors_buf ||= [])
    orgs_buf = (@_story_card_orgs_buf ||= [])
    cards_buf = (@_story_card_cards_buf ||= [])
    view_buf = (@_story_card_view_buf ||= [])
    tag_colors_buf = (@_story_card_tag_colors_buf ||= [])
    reaction_icons_buf = (@_story_card_reaction_icons_buf ||= [])
    authors_buf.clear
    orgs_buf.clear
    cards_buf.clear
    view_buf.clear
    tag_colors_buf.clear
    reaction_icons_buf.clear

    feed_pref = if options.key?(:feed_style_preference)
                  options[:feed_style_preference]
                elsif respond_to?(:feed_style_preference)
                  feed_style_preference
                else
                  Settings::UserExperience.feed_style
                end
    feed_style_rich = feed_pref == "rich"
    curation_view = truthy_bool(options[:curation_view])
    has_explicit_show_org = options.key?(:show_organization)
    default_show_org = has_explicit_show_org ? truthy_bool(options[:show_organization]) : !@organization_article_index

    signed_in = begin
      respond_to?(:user_signed_in?) && truthy_bool(user_signed_in?)
    rescue StandardError
      false
    end
    show_bookmark_buttons = truthy_bool(options[:is_home_feed]) && signed_in
    assigned_user_id = show_bookmark_buttons && @user ? @user.id : nil

    url_signed_in = RequestStore.store[:user_signed_in]
    is_on_custom_domain = RequestStore.store[:custom_domain_org].present?
    subforem_disabled = Subforem.disabled_by_env?
    default_subforem_id = subforem_disabled ? nil : RequestStore.store[:default_subforem_id]
    default_domain = default_subforem_id ? Subforem.cached_id_to_domain_hash[default_subforem_id] : nil
    default_base_url = URL.url(nil, default_domain).to_s
    base_url_joinable = !ForemNative.join_url(default_base_url, "/").nil?

    cover_mode_kind, cf_domain, cf_dir, cf_height, cf_fit, cf_prefix = resolve_story_cover_mode

    total_stories = stories.size
    records = Array.new(total_stories)
    i = 0
    while i < total_stories
      story = stories[i]
      record = story.is_a?(ApplicationDecorator) ? story.object : story
      return unless record.is_a?(Article)

      records[i] = record
      i += 1
    end

    if total_stories > 1
      unpreloaded_reactions = records.select do |rec|
        rec.public_reactions_count.to_i.positive? &&
          !rec.instance_variable_defined?(:@preloaded_reaction_counts_for_reactable)
      end
      Article.preload_reaction_counts_for_reactable(unpreloaded_reactions) if unpreloaded_reactions.any?
    end

    flare_map = FlareTag::FLARE_TAG_IDS_HASH
    allowed_flare_tags = flare_map.keys
    valid_flare_tags = flare_map.empty? ? [] : FlareTag.tags_by_id.values.map(&:name)
    except_flare_tag = @tag.is_a?(String) || @tag.nil? ? @tag : @tag.to_s

    primary_hex = static_ctx[10]
    unique_tag_names = []
    seen_tags = {}
    author_indices = {}
    org_indices = {}
    reaction_icon_indices_map = {}
    reaction_icon_cache = (@_story_card_reaction_icon_cache ||= {})
    viewer_id_for_curation = nil
    viewer_id_fetched = false

    idx = 0
    while idx < total_stories
      story = stories[idx]
      record = records[idx]
      cu = record.cached_user
      return unless cu

      is_sub = cu.respond_to?(:cached_base_subscriber?) && truthy_bool(cu.cached_base_subscriber?)
      is_leader = truthy_bool(cu.try(:cached_community_leader?))
      u_name = cu.name.to_s
      u_username = cu.username.to_s
      u_img = cu.profile_image_90.to_s
      u_id = record.user_id
      return unless u_id.is_a?(Integer)

      author_key = [u_id, u_name, u_username, u_img, is_sub, is_leader]
      author_idx = author_indices[author_key]
      unless author_idx
        author_idx = author_indices.size
        author_indices[author_key] = author_idx
        authors_buf.push(u_id, u_name, u_username, u_img, is_sub, is_leader)
      end

      co = record.cached_organization
      show_org = truthy_bool(co) && default_show_org
      org_idx = nil
      if show_org
        o_slug = co.slug.to_s
        o_name = co.name.to_s
        o_img = co.profile_image_90.to_s
        org_key = [o_slug, o_name, o_img]
        org_idx = org_indices[org_key]
        unless org_idx
          org_idx = org_indices.size
          org_indices[org_key] = org_idx
          orgs_buf.push(o_slug, o_name, o_img)
        end
      end

      featured = resolve_story_flag(story, options, :featured, :featured_for, :featured_ids)
      pinned = resolve_story_flag(story, options, :pinned, :pinned_for, :pinned_ids)

      type_of = record.type_of.to_s
      title = record.title.to_s
      path = record.path.to_s
      return if record.id.nil?

      needs_org_url = (!url_signed_in || is_on_custom_domain) &&
        record.has_attribute?(:organization_id) && record.organization_id.present?
      needs_subforem_url = !subforem_disabled &&
        record.has_attribute?(:subforem_id) &&
        (record.subforem_id || default_subforem_id) != default_subforem_id
      explicit_article_url = if !base_url_joinable || needs_org_url || needs_subforem_url || !path.ascii_only?
                               URL.article(record).to_s
                             end

      main_image = record.main_image
      explicit_cover_url = if main_image.present? && cover_url_requires_ruby?(main_image, cover_mode_kind, cf_prefix)
                             cloud_cover_url(main_image).to_s
                           end

      video = record.video
      video_thumb = record.video_thumbnail_url
      cloudinary_vid_url = nil
      video_dur_str = nil
      if video.present? && video_thumb.present? && video.exclude?("youtube") && video.exclude?("player.mux.com")
        cloudinary_vid_url = record.cloudinary_video_url&.to_s
        video_dur_str = record.video_duration_in_minutes.to_s
      end

      note = record.context_notes.first
      note_html = note && note.processed_html.present? ? note.processed_html.to_s : nil

      disp_pub = record.displayable_published_at
      pub_int = record.published_at.to_i

      raw_tags = record.cached_tag_list.to_s
      if type_of != "status" && !raw_tags.empty?
        collect_unique_story_tags(raw_tags, seen_tags, unique_tag_names)
      end

      status_preview = nil
      if type_of == "status" && record.has_attribute?(:processed_html) && record.processed_html.present?
        raw_proc = record.processed_html.to_s
        status_preview = if raw_proc.include?("runkit-element")
                           record.__send__(:replace_legacy_code_html, raw_proc)
                         else
                           raw_proc
                         end
      end

      pub_reactions = record.public_reactions_count.to_i
      card_reaction_indices = nil
      if pub_reactions.positive?
        cats = record.public_reaction_categories.reverse
        card_reaction_indices = cats.map do |cat|
          icon_name = cat.icon.to_s
          r_idx = reaction_icon_indices_map[icon_name]
          unless r_idx
            r_idx = reaction_icons_buf.size
            reaction_icon_indices_map[icon_name] = r_idx
            icon_html = (reaction_icon_cache[icon_name] ||= image_tag("#{icon_name}.svg", size: "18x18").to_s)
            reaction_icons_buf << icon_html
          end
          r_idx
        end
      end

      fav_uid = record.favorited_by_user_id
      picker_state = 0
      picker_username = nil
      if curation_view && fav_uid.present?
        if signed_in && !viewer_id_fetched
          viewer_id_for_curation = current_user&.id
          viewer_id_fetched = true
        end
        picker_state, picker_username = resolve_curation_picker(record, fav_uid, viewer_id_for_curation)
      end

      cards_buf.push(
        record.id,
        author_idx,
        org_idx,
        featured,
        pinned,
        type_of,
        title,
        path,
        explicit_article_url,
        main_image&.to_s,
        explicit_cover_url,
        record.main_image_height,
        record.main_image_background_hex_color&.to_s,
        video&.to_s,
        video_thumb&.to_s,
        cloudinary_vid_url,
        video_dur_str,
        note_html,
        truthy_bool(record.published),
        disp_pub&.tv_sec,
        disp_pub ? disp_pub.utc_offset : 0,
        pub_int,
        raw_tags,
        status_preview,
        pub_reactions,
        card_reaction_indices,
        fav_uid,
        picker_state,
        picker_username,
        record.comments_count.to_i,
        record.reading_time.to_i,
      )
      idx += 1
    end

    populate_story_tag_colors_buf(unique_tag_names, primary_hex, total_stories > 1, tag_colors_buf)

    view_buf.push(
      feed_style_rich,
      curation_view,
      show_bookmark_buttons,
      assigned_user_id,
      Time.current.year,
      default_base_url,
      cover_mode_kind,
      cf_domain,
      cf_dir,
      cf_height,
      cf_fit,
      except_flare_tag,
      allowed_flare_tags,
      valid_flare_tags,
      reaction_icons_buf,
      tag_colors_buf,
    )

    html = ForemNative.render_story_cards(static_ctx, view_buf, authors_buf, orgs_buf, cards_buf)
    html&.html_safe
  rescue StandardError
    nil
  end

  def resolve_story_cover_mode
    return [2, "", "", "", "", nil] unless method(:cloud_cover_url).owner == ApplicationHelper
    return [0, "", "", "", "", nil] if Rails.env.development?

    if !Images::Optimizer.imgproxy_enabled? && !Images::Optimizer.cloudinary_enabled?
      if Images::Optimizer.cloudflare_enabled?
        subforem_id = RequestStore.store[:subforem_id]
        cf_domain = ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"].to_s
        cf_dir = Images::Optimizer::CLOUDFLARE_DIRECTORY.to_s
        cf_height = Settings::UserExperience.cover_image_height(subforem_id: subforem_id).to_s
        crop = Settings::UserExperience.cover_image_fit(subforem_id: subforem_id)
        cf_fit = crop == "crop" ? "cover" : "scale-down"
        [1, cf_domain, cf_dir, cf_height, cf_fit, Images::Optimizer.cloudflare_prefix]
      else
        [0, "", "", "", "", nil]
      end
    else
      [2, "", "", "", "", nil]
    end
  end

  def story_card_static_context
    encoding = ActiveSupport::JSON::Encoding
    return unless encoding.json_encoder == encoding::JSONGemEncoder

    fav_enabled = truthy_bool(FeatureFlag.enabled?(:community_favorites))
    sub_enabled = truthy_bool(FeatureFlag.enabled?("subscriber_icon"))
    primary_hex = Settings::UserExperience.primary_brand_color_hex.presence || "#3b49df"
    escape_json = truthy_bool(encoding.escape_html_entities_in_json)
    prior_cf = ApplicationConfig["PRIOR_CLOUDFLARE_IMAGES_DOMAIN"].presence
    current_cf = ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"].presence
    rng_loc = InlineSvg::IdGenerator::Randomness.method(:call).source_location

    cache_key = [
      I18n.locale,
      fav_enabled,
      sub_enabled,
      primary_hex,
      escape_json,
      prior_cf,
      current_cf,
      rng_loc,
    ]
    if @_story_card_static_key == cache_key && @_story_card_static_ctx
      return @_story_card_static_ctx
    end

    abbr_months = I18n.t("date.abbr_month_names")
    return unless abbr_months.is_a?(Array) && abbr_months.size >= 13

    months_12 = abbr_months[1, 12].map(&:to_s)
    return unless months_12.size == 12

    sub_icon_html = if sub_enabled
                      link_to(
                        image_tag("subscription-icon.png", alt: "Subscriber", class: "subscription-icon"),
                        "/++",
                        style: "display: inline;",
                      ).to_s
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

    hidden_span_start = tag("span", { class: %w[hidden s:inline] }, true)
    span_end = "</span>".html_safe
    sentinel_str = COUNT_SENTINEL.to_s

    ctx = [
      sub_icon_html,
      leader_icon_html,
      fav_enabled,
      crayons_icon_tag("favorite-checked", native: true, width: 14, height: 14, class: "mr-1").to_s,
      inline_svg_tag("pin.svg", alt: "", aria_hidden: true, class: "mr-1 align-text-bottom color-accent-brand").to_s,
      crayons_icon_tag("small-favorite-filled", title: t("favorites.favorited")).to_s,
      crayons_icon_tag("small-favorite-checked", title: t("favorites.favorited_by_you")).to_s,
      crayons_icon_tag("small-comment", title: t("views.comments.summary.title")).to_s,
      inline_svg_tag("small-save.svg", alt: "", aria_hidden: true).to_s,
      inline_svg_tag("small-save-filled.svg", alt: "", aria_hidden: true).to_s,
      primary_hex.to_s,
      escape_json,
      I18n.t("views.users.details", user: USER_PLACEHOLDER).to_s,
      t("views.users.follow").to_s,
      t(
        "views.articles.for_org_html",
        start: tag("span", { class: %w[crayons-story__tertiary fw-normal] }, true),
        end: span_end,
        org: ORG_PLACEHOLDER.html_safe,
      ).to_s,
      t("views.leadership.cards.picked_by_you").to_s,
      I18n.t("views.leadership.cards.picked_by_user", username: USER_PLACEHOLDER).to_s,
      t("favorites.favorited").to_s,
      t("views.pins.article").to_s,
      I18n.t("views.articles.comments.aria_label", title: TITLE_PLACEHOLDER).to_s,
      t("views.reactions.summary.count_html", count: 1, start: hidden_span_start, end: span_end).to_s,
      t("views.reactions.summary.count_html", count: COUNT_SENTINEL, start: hidden_span_start, end: span_end)
        .to_s.sub(sentinel_str, COUNT_PLACEHOLDER),
      t("views.leadership.cards.start_discussion").to_s,
      t("views.leadership.cards.further_discussion").to_s,
      I18n.t("views.leadership.cards.comments_count", count: 1).to_s,
      I18n.t("views.leadership.cards.comments_count", count: COUNT_SENTINEL).to_s.sub(sentinel_str, COUNT_PLACEHOLDER),
      t("views.comments.summary.count_html", count: 1, start: hidden_span_start, end: span_end).to_s,
      t("views.comments.summary.count_html", count: COUNT_SENTINEL, start: hidden_span_start, end: span_end)
        .to_s.sub(sentinel_str, COUNT_PLACEHOLDER),
      t("views.comments.add").to_s,
      I18n.t("views.articles.reading_time", count: 1).to_s,
      I18n.t("views.articles.reading_time", count: COUNT_SENTINEL).to_s.sub(sentinel_str, COUNT_PLACEHOLDER),
      I18n.t("views.articles.save.aria_label", title: TITLE_PLACEHOLDER).to_s,
      I18n.t("views.articles.save.title", title: TITLE_PLACEHOLDER).to_s,
      I18n.t("time.formats.short").to_s,
      I18n.t("time.formats.short_with_yy").to_s,
      months_12,
      prior_cf,
      current_cf,
    ]

    @_story_card_static_key = cache_key
    @_story_card_static_ctx = ctx
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Rails/HelperInstanceVariable, Rails/OutputSafety
end
