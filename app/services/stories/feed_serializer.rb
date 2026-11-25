module Stories
  # Single-pass streaming JSON serializer for `Stories::FeedsController#show`
  # (`GET /stories/feed`) backed by `ForemNative.serialize_stories_feed_json`.
  #
  # Splices pre-serialized JSON object fragments on cache hits without Marshal
  # deserialization or Ruby Hash copies, streams uncached stories directly into
  # one pre-sized Rust buffer without Jbuilder or `Comment#decorate` allocations,
  # and batch-writes newly serialized cache misses via `Rails.cache.write_multi`.
  #
  # Returns `nil` for any out-of-domain input so the controller transparently
  # falls back to `app/views/stories/feeds/show.json.jbuilder`.
  class FeedSerializer
    # Reserved namespace: entries under this prefix must only ever be written by
    # this serializer (`persist_new_fragments`), because cached fragments are
    # spliced into the HTTP response without re-encoding. Bump the version when
    # the fragment schema, key order, or JSON escaping rules change.
    CACHE_KEY_PREFIX = "stories_feed/v1/article".freeze
    CACHE_EXPIRES_IN = 6.hours

    def self.native_supported?
      ForemNative.available? &&
        ForemNative::Native.respond_to?(:serialize_stories_feed_json) &&
        ActiveSupport::JSON::Encoding.use_standard_json_time_format &&
        ActiveSupport::JSON::Encoding.time_precision == 3 &&
        !Images::Optimizer.imgproxy_enabled? &&
        !Images::Optimizer.cloudinary_enabled?
    end

    def self.cache_key_for(record)
      cache_generation = ENV["RAILS_CACHE_ID"].presence || ENV["RAILS_APP_VERSION"].presence
      prefix = cache_generation ? "#{CACHE_KEY_PREFIX}/#{cache_generation}" : CACHE_KEY_PREFIX
      [
        prefix,
        record.id,
        record.updated_at,
        record.edited_at,
        record.last_comment_at,
        record.public_reactions_count,
        record.favorited_by_user_id,
        record.cached_user,
        record.cached_organization,
        I18n.locale,
      ].join("-")
    end

    def self.call(
      stories:,
      comments_variant:,
      user_signed_in:,
      feed_config_id:,
      view_context:,
      cached_story_fragments: nil,
      story_cache_keys: nil,
      cache_writes_enabled: false,
      cached_subforem_logo: nil,
      cached_subforem_logos: nil
    )
      new(
        stories: stories,
        comments_variant: comments_variant,
        user_signed_in: user_signed_in,
        feed_config_id: feed_config_id,
        view_context: view_context,
        cached_story_fragments: cached_story_fragments,
        story_cache_keys: story_cache_keys,
        cache_writes_enabled: cache_writes_enabled,
        cached_subforem_logo: cached_subforem_logo,
        cached_subforem_logos: cached_subforem_logos,
      ).call
    end

    def initialize(
      stories:,
      comments_variant:,
      user_signed_in:,
      feed_config_id:,
      view_context:,
      cached_story_fragments:,
      story_cache_keys:,
      cache_writes_enabled:,
      cached_subforem_logo:,
      cached_subforem_logos:
    )
      @stories = stories
      @comments_variant = comments_variant
      @user_signed_in = user_signed_in ? true : false
      @feed_config_id = feed_config_id
      @view_context = view_context
      @cached_story_fragments = cached_story_fragments
      @story_cache_keys = story_cache_keys
      @cache_writes_enabled = cache_writes_enabled
      @cached_subforem_logo = cached_subforem_logo
      @cached_subforem_logos = cached_subforem_logos
    end

    def call
      return unless self.class.native_supported?
      return "[]" if @stories.empty?

      payload = build_native_payload
      return unless payload

      result = ForemNative.serialize_stories_feed_json(*payload[:args])
      return unless result

      json_body, new_fragments = result
      persist_new_fragments(payload[:uncached_cache_keys], new_fragments)
      json_body
    end

    private

    def build_native_payload
      entries_flat = []
      uncached_articles = []
      uncached_cache_keys = []

      @stories.each do |story|
        article = story.respond_to?(:object) ? story.object : story
        cache_key = @story_cache_keys&.[](article.id)
        cached_fragment = cache_key ? @cached_story_fragments&.[](cache_key) : nil
        cached_fragment = nil unless cached_fragment.is_a?(String)

        entries_flat.push(cached_fragment, URL.article(story), @user_signed_in, @feed_config_id)
        next if cached_fragment

        uncached_articles << article
        uncached_cache_keys << (cache_key || self.class.cache_key_for(article)) if @cache_writes_enabled
      end

      uncached_data = build_uncached_payloads(uncached_articles)
      return unless uncached_data

      {
        args: [
          entries_flat,
          uncached_data[:items_flat],
          uncached_data[:comments_flat],
          uncached_data[:comment_lens],
          uncached_data[:reaction_counts_flat],
          uncached_data[:reaction_counts_lens],
          native_reaction_categories_payload(uncached_articles.any?),
          native_config_payload(capture_fragments: @cache_writes_enabled && uncached_articles.any?),
        ],
        uncached_cache_keys: uncached_cache_keys
      }
    end

    def build_uncached_payloads(uncached_articles)
      items_flat = []
      comments_flat = []
      comment_lens = []
      reaction_counts_flat = []
      reaction_counts_lens = []

      if uncached_articles.any?
        pinned_id = PinnedArticle.id
        flare_tags = FlareTag.tags_by_article_id(uncached_articles)
        use_english_utc = I18n.locale == :en && Time.current.utc_offset.zero?
        comments_method = @comments_variant.to_sym

        uncached_articles.each do |article|
          return nil unless append_article_payload(
            article, items_flat, pinned_id, flare_tags[article.id], use_english_utc
          )
          return nil unless append_comments_payload(article, comments_method, comments_flat, comment_lens)

          append_reaction_counts_payload(article, reaction_counts_flat, reaction_counts_lens)
        end
      end

      {
        items_flat: items_flat,
        comments_flat: comments_flat,
        comment_lens: comment_lens,
        reaction_counts_flat: reaction_counts_flat,
        reaction_counts_lens: reaction_counts_lens
      }
    end

    def append_article_payload(article, items_flat, pinned_id, flare_tag, use_english_utc)
      cached_user = article.cached_user
      return false unless cached_user.is_a?(Articles::CachedEntity)

      has_org = article.cached_organization?
      cached_org = has_org ? article.cached_organization : nil
      return false if has_org && !cached_org.is_a?(Articles::CachedEntity)

      edited_sec, edited_ms = extract_utc_edited_at(article.edited_at)
      return false if article.edited_at && edited_sec.nil?

      video_duration_secs = integer_video_duration(article.video_duration_in_seconds)
      return false if video_duration_secs.nil?

      push_article_core_fields(article, items_flat, edited_sec, edited_ms)
      push_cached_entity_fields(cached_user, items_flat)
      items_flat.push(has_org)
      push_cached_entity_fields(cached_org, items_flat)
      push_article_derived_fields(article, items_flat, pinned_id, flare_tag, use_english_utc,
                                  video_duration_secs)
      true
    end

    # `articles.video_duration_in_seconds` is a float column; truncate it with
    # `to_i` exactly like `Article#legacy_video_duration_in_minutes` so the
    # native kernel receives an Integer. Returns `nil` (Jbuilder fallback) for
    # non-finite, negative, or out-of-range values.
    def integer_video_duration(seconds)
      return 0 if seconds.nil?
      return unless seconds.is_a?(Integer) || (seconds.is_a?(Float) && seconds.finite?)

      secs = seconds.to_i
      return if secs.negative? || secs >= 2**62

      secs
    end

    def extract_utc_edited_at(edited_at)
      return [nil, nil] unless edited_at
      return [nil, nil] unless edited_at.utc_offset.zero?

      [edited_at.to_i, edited_at.usec / 1000]
    end

    def push_article_core_fields(article, items_flat, edited_sec, edited_ms)
      items_flat.push(
        article.title, article.path, article.id, article.user_id, article.comments_count,
        article.public_reactions_count, article.organization_id, article.reading_time,
        article.video_thumbnail_url, article.video, edited_sec, edited_ms,
        article.experience_level_rating, article.experience_level_rating_distribution,
        article.main_image_height, article.type_of, article.subforem_id,
        article.favorited_by_user_id, article.ai_disclosure_level
      )
    end

    def push_cached_entity_fields(entity, items_flat)
      if entity
        items_flat.push(
          entity.name, entity.username, entity.slug, entity.profile_image_90,
          entity.profile_image_url, entity[:cached_base_subscriber?], entity[:cached_community_leader?]
        )
      else
        items_flat.push(nil, nil, nil, nil, nil, nil, nil)
      end
    end

    def push_article_derived_fields(article, items_flat, pinned_id, flare_tag, use_english_utc,
                                    video_duration_secs)
      displayable_at = article.displayable_published_at
      use_native_readable_date = use_english_utc && (displayable_at.nil? || displayable_at.utc_offset.zero?)
      is_status = article.type_of == "status"
      main_image = article.main_image? ? @view_context.cloud_cover_url(article.main_image, article.subforem_id) : nil

      items_flat.push(
        article.persisted? && article.id == pinned_id,
        main_image,
        article.cached_tag_list,
        is_status ? article.body_preview : nil,
        is_status ? article.title_finalized_for_feed : nil,
        is_status ? article.title_for_metadata : nil,
        !flare_tag.nil?,
        flare_tag&.name,
        flare_tag&.bg_color_hex,
        flare_tag&.text_color_hex,
        article.class_name,
        article.published ? true : false,
        article.published_at.to_i,
        displayable_at&.to_i,
        article.main_image_background_hex_color,
        use_native_readable_date ? nil : article.readable_publish_date,
        video_duration_secs,
        resolve_subforem_logo(article.subforem_id),
        article.context_notes.first&.processed_html,
      )
    end

    def append_comments_payload(article, comments_method, comments_flat, comment_lens)
      if article.comments_count.to_i <= 0
        comment_lens << 0
        return true
      end

      comments = article.public_send(comments_method).first(3)
      comments.each do |comment|
        user = comment.user
        return false unless user

        comments_flat.push(
          comment.id,
          comment.user_id,
          comment.created_at&.to_i,
          comment.safe_processed_html&.to_str,
          comment.path,
          user.username,
          user.name,
          user.profile_image_90,
        )
      end
      comment_lens << comments.size
      true
    end

    def append_reaction_counts_payload(article, reaction_counts_flat, reaction_counts_lens)
      counts = if article.instance_variable_defined?(:@preloaded_reaction_counts_for_reactable)
                 article.instance_variable_get(:@preloaded_reaction_counts_for_reactable)
               else
                 article.__send__(:reaction_counts_for_reactable)
               end

      count = 0
      counts.each do |entry|
        reaction_counts_flat.push(entry[:category].to_s, entry[:count].to_i)
        count += 1
      end
      reaction_counts_lens << count
    end

    def resolve_subforem_logo(subforem_id)
      if @cached_subforem_logo
        @cached_subforem_logo
      elsif @cached_subforem_logos
        @cached_subforem_logos[subforem_id] ||= Settings::General.logo_png(subforem_id: subforem_id)
      else
        Settings::General.logo_png(subforem_id: subforem_id)
      end
    end

    def native_reaction_categories_payload(has_uncached)
      return [] unless has_uncached

      ReactionCategory.for_view.flat_map do |category|
        [category.slug.to_s, category.name, category.icon, category.position]
      end
    end

    def native_config_payload(capture_fragments:)
      cf_enabled = Images::Optimizer.cloudflare_enabled?
      [
        Time.current.year,
        cf_enabled ? 1 : 0,
        cf_enabled ? ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"] : nil,
        Images::Optimizer::CLOUDFLARE_DIRECTORY,
        ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
        I18n.t("models.article.ai_disclosure.some_ai"),
        I18n.t("models.article.ai_disclosure.fully_autonomous"),
        I18n.t("models.article.ai_disclosure.no_ai"),
        I18n.t("models.article.ai_disclosure.not_disclosed"),
        capture_fragments,
      ]
    end

    def persist_new_fragments(cache_keys, new_fragments)
      return if cache_keys.empty? || new_fragments.empty?
      return unless cache_keys.size == new_fragments.size

      writes = {}
      cache_keys.each_with_index do |key, idx|
        writes[key] = new_fragments[idx]
      end
      Rails.cache.write_multi(writes, expires_in: CACHE_EXPIRES_IN)
    end
  end
end
