require "base64"
require "json"

module EdgeFeed
  # Builds compact, viewer-independent Fastly KV snapshots for a subforem's custom
  # `FeedConfig`-derived home feed:
  #
  #   1. `snapshot:<subforem_id>`   — qualified article scoring index + active FeedConfigs + settings
  #   2. `cards:<subforem_id>:<k>`  — sharded pre-rendered story card JSON payloads (viewer-independent)
  #   3. `embeddings:<subforem_id>` — symmetric int8-quantized 768-dim embeddings (only for recent articles)
  #   4. `host_map`                 — domain -> subforem_id routing map
  class SnapshotBuilder
    SNAPSHOT_VERSION = 1
    DEFAULT_CARD_SHARD_COUNT = 8
    MAX_CONFIGS_PER_BUCKET = 100
    UNRENDERED_COMMENT_COLUMNS = %w[body_markdown body_html semantic_embedding].freeze

    CARD_ATTRIBUTES = %i[
      title path id user_id comments_count public_reactions_count organization_id
      reading_time video_thumbnail_url video edited_at
      experience_level_rating experience_level_rating_distribution main_image_height
      type_of subforem_id favorited_by_user_id ai_disclosure_level
    ].freeze

    CARD_METHODS = %i[
      flare_tag class_name cloudinary_video_url published_at_int
      published_timestamp main_image_background_hex_color
      public_reaction_categories readable_publish_date video_duration_in_minutes
      ai_disclosure_label
    ].freeze

    Result = Struct.new(:snapshot, :card_shards, :embeddings, keyword_init: true)

    def self.build_host_map
      mapping = {}
      if Subforem.disabled_by_env?
        default_id = Subforem.cached_default_id
        app_domain = Settings::General.app_domain.to_s.downcase.presence
        mapping[app_domain] = default_id if default_id && app_domain
        return mapping
      end

      Subforem.cached_id_to_domain_hash.each do |subforem_id, domain|
        next if domain.blank?

        normalized = domain.to_s.downcase
        mapping[normalized] = subforem_id
        mapping["www.#{normalized}"] ||= subforem_id unless normalized.start_with?("www.")
      end
      mapping
    end

    def initialize(subforem_id:, card_shard_count: DEFAULT_CARD_SHARD_COUNT, now: Time.current)
      @subforem_id = subforem_id
      @card_shard_count = [card_shard_count.to_i, 1].max
      @now = now
    end

    def build
      with_subforem_context { build_within_context }
    end

    private

    def build_within_context
      root_subforem_id = Subforem.cached_root_id
      is_root = !Subforem.disabled_by_env? && @subforem_id.present? && @subforem_id == root_subforem_id

      lookback_days = resolve_lookback_days
      pinned_article = PinnedArticle.get
      articles = ensure_pinned_article_included(load_qualified_articles(@now - lookback_days.days), pinned_article)
      preload_card_associations(articles)

      subforem_logos = preload_subforem_logos(articles, is_root: is_root)
      snapshot = build_snapshot_payload(
        articles: articles, configs: load_active_feed_configs,
        is_root: is_root, lookback_days: lookback_days, pinned_article_id: pinned_article&.id
      )

      Result.new(
        snapshot: snapshot,
        card_shards: build_card_shards(articles, pinned_article_id: pinned_article&.id, subforem_logos: subforem_logos),
        embeddings: build_quantized_embeddings(articles),
      )
    end

    def build_snapshot_payload(articles:, configs:, is_root:, lookback_days:, pinned_article_id:)
      {
        version: SNAPSHOT_VERSION,
        generated_at_sec: @now.to_i,
        subforem_id: @subforem_id,
        is_root_subforem: is_root,
        feed_lookback_days: lookback_days,
        feed_strategy: Settings::UserExperience.feed_strategy(subforem_id: @subforem_id).to_s,
        sticky_hours: Settings::UserExperience.feed_config_sticky_hours(subforem_id: @subforem_id).to_i,
        sticky_percentage: Settings::UserExperience.feed_config_sticky_percentage(subforem_id: @subforem_id).to_i,
        pinned_article_id: pinned_article_id,
        card_shard_count: @card_shard_count,
        configs: configs.map { |cfg| serialize_config(cfg) },
        articles: articles.map { |article| serialize_article_index(article) }
      }
    end

    def with_subforem_context
      prev_subforem_id = RequestStore.store[:subforem_id]
      prev_root_id = RequestStore.store[:root_subforem_id]
      prev_default_id = RequestStore.store[:default_subforem_id]

      RequestStore.store[:subforem_id] = @subforem_id
      RequestStore.store[:root_subforem_id] = Subforem.cached_root_id
      RequestStore.store[:default_subforem_id] = Subforem.cached_default_id
      yield
    ensure
      RequestStore.store[:subforem_id] = prev_subforem_id
      RequestStore.store[:root_subforem_id] = prev_root_id
      RequestStore.store[:default_subforem_id] = prev_default_id
    end

    def resolve_lookback_days
      configured = Settings::UserExperience.feed_lookback_days(subforem_id: @subforem_id).to_i
      configured.positive? ? configured : FeedConfig::DEFAULT_FEED_LOOKBACK_DAYS
    end

    def load_qualified_articles(lookback_cutoff)
      Article.published
        .with_at_least_home_feed_minimum_score
        .where("articles.published_at > ?", lookback_cutoff)
        .from_subforem
        .limited_column_select
        .select(
          :comment_score, :feed_success_score, :clickbait_score, :compellingness_score,
          :featured, :language, :cached_label_list, :last_comment_at
        )
        .to_a
    end

    def ensure_pinned_article_included(articles, pinned_article)
      return articles if pinned_article.nil? || articles.any? { |a| a.id == pinned_article.id }

      articles + [pinned_article]
    end

    def load_active_feed_configs
      buckets = [FeedConfig::BUCKET_ALL, *FeedConfig::FEED_TARGETING_BUCKETS]
      buckets.flat_map do |bucket|
        scope = FeedConfig.active.where(targeting_bucket: bucket)
        newest_low = scope.where("feed_impressions_count < ?", FeedConfig::LOW_IMPRESSION_COUNT)
          .order(created_at: :desc)
          .limit(FeedConfig::TOP_POOL_LIMIT)
          .to_a
        top_scored = scope.order(feed_success_score: :desc, id: :desc)
          .limit(MAX_CONFIGS_PER_BUCKET)
          .to_a
        (newest_low + top_scored).uniq(&:id)
      end.uniq(&:id)
    end

    def serialize_config(cfg)
      {
        id: cfg.id,
        targeting_bucket: cfg.targeting_bucket.to_s,
        created_at_sec: cfg.created_at.to_i,
        feed_impressions_count: cfg.feed_impressions_count.to_i,
        feed_success_score: cfg.feed_success_score.to_f,
        shuffle_weight: cfg.shuffle_weight.to_f,
        recent_page_views_shuffle_weight: cfg.recent_page_views_shuffle_weight.to_f,
        semantic_candidate_limit: cfg.effective_semantic_candidate_limit,
        feed_lookback_hours: cfg.feed_lookback_hours.to_i,
        recent_tag_count_min: cfg.recent_tag_count_min.to_i,
        recent_tag_count_max: cfg.recent_tag_count_max.to_i,
        all_time_tag_count_min: cfg.all_time_tag_count_min.to_i,
        all_time_tag_count_max: cfg.all_time_tag_count_max.to_i,
        weights: {
          feed_success_weight: cfg.feed_success_weight.to_f,
          comment_score_weight: cfg.comment_score_weight.to_f,
          score_weight: cfg.score_weight.to_f,
          organization_follow_weight: cfg.organization_follow_weight.to_f,
          user_follow_weight: cfg.user_follow_weight.to_f,
          follow_status_weight: cfg.follow_status_weight.to_f,
          tag_follow_weight: cfg.tag_follow_weight.to_f,
          subforem_follow_weight: cfg.subforem_follow_weight.to_f,
          label_match_weight: cfg.label_match_weight.to_f,
          recency_weight: cfg.recency_weight.to_f,
          comment_recency_weight: cfg.comment_recency_weight.to_f,
          lookback_window_weight: cfg.lookback_window_weight.to_f,
          precomputed_selections_weight: cfg.precomputed_selections_weight.to_f,
          recent_article_suppression_rate: cfg.recent_article_suppression_rate.to_f,
          published_today_weight: cfg.published_today_weight.to_f,
          general_past_day_bonus_weight: cfg.general_past_day_bonus_weight.to_f,
          recently_active_past_day_bonus_weight: cfg.recently_active_past_day_bonus_weight.to_f,
          recent_subforem_weight: cfg.recent_subforem_weight.to_f,
          semantic_similarity_weight: cfg.semantic_similarity_weight.to_f,
          ai_disclosure_matching_weight: cfg.ai_disclosure_matching_weight.to_f,
          autonomous_ai_penalty_weight: cfg.autonomous_ai_penalty_weight.to_f,
          featured_weight: cfg.featured_weight.to_f,
          favorited_weight: cfg.favorited_weight.to_f,
          status_weight: cfg.status_weight.to_f,
          clickbait_score_weight: cfg.clickbait_score_weight.to_f,
          compellingness_score_weight: cfg.compellingness_score_weight.to_f,
          language_match_weight: cfg.language_match_weight.to_f,
          randomness_weight: cfg.randomness_weight.to_f,
          published_at_diversity_weight: cfg.published_at_diversity_weight.to_f
        }
      }
    end

    def serialize_article_index(article)
      {
        id: article.id,
        user_id: article.user_id,
        organization_id: article.organization_id,
        subforem_id: article.subforem_id,
        published_at_sec: article.published_at.to_i,
        last_comment_at_sec: article.last_comment_at&.to_i,
        score: article.score.to_f,
        comment_score: article.comment_score.to_f,
        feed_success_score: article.feed_success_score.to_f,
        clickbait_score: article.clickbait_score.to_f,
        compellingness_score: article.compellingness_score.to_f,
        featured: article.featured == true,
        favorited: article.favorited_by_user_id.present?,
        type_of: Article.type_ofs[article.type_of.to_s] || 0,
        ai_disclosure_level: Article.ai_disclosure_levels[article.ai_disclosure_level.to_s] || 0,
        language: article.language,
        tags: article.cached_tag_list_array,
        labels: Array(article.cached_label_list).compact_blank,
        url: URL.article(article)
      }
    end

    def preload_card_associations(articles)
      return if articles.empty?

      ActiveRecord::Associations::Preloader.new(
        records: articles,
        associations: :context_notes,
        scope: ContextNote.order(:id),
      ).call

      commented = articles.select { |r| r.comments_count.to_i.positive? }
      if commented.any?
        columns = Comment.column_names - UNRENDERED_COMMENT_COLUMNS
        ranked = Comment.where(
          commentable_type: "Article",
          commentable_id: commented.map(&:id),
          score: 5..,
          ancestry: nil,
          hidden_by_commentable_user: false,
          deleted: false,
        ).select(*columns)
          .select("ROW_NUMBER() OVER (PARTITION BY commentable_id ORDER BY created_at DESC) AS feed_comment_rank")
        ActiveRecord::Associations::Preloader.new(
          records: commented,
          associations: :more_inclusive_recent_good_comments,
          scope: Comment.from(ranked, :comments).where("feed_comment_rank <= 3").select(*columns).includes(:user),
        ).call
      end

      with_reactions, without_reactions = articles.partition { |r| r.public_reactions_count.to_i.positive? }
      without_reactions.each { |r| r.instance_variable_set(:@preloaded_reaction_counts_for_reactable, []) }
      Article.preload_reaction_counts_for_reactable(with_reactions) if with_reactions.any?
    end

    def preload_subforem_logos(articles, is_root:)
      logos = { @subforem_id => Settings::General.logo_png(subforem_id: @subforem_id) }
      return logos unless is_root

      articles.map(&:subforem_id).uniq.compact.each do |sf_id|
        logos[sf_id] ||= Settings::General.logo_png(subforem_id: sf_id)
      end
      logos
    end

    def build_card_shards(articles, pinned_article_id:, subforem_logos:)
      shards = Array.new(@card_shard_count) { {} }
      decorated = ArticleDecorator.decorate_collection(articles)

      decorated.each do |article|
        shard_idx = article.id % @card_shard_count
        shards[shard_idx][article.id.to_s] = serialize_story_card(
          article,
          pinned: pinned_article_id == article.id,
          subforem_logo: subforem_logos[article.subforem_id] || subforem_logos[@subforem_id],
        )
      end

      shards
    end

    # Mirrors `app/views/stories/feeds/show.json.jbuilder` (minus the 3 per-request fields
    # `url`, `current_user_signed_in`, and `feed_config` spliced at the edge).
    def serialize_story_card(article, pinned:, subforem_logo:)
      card = {}
      CARD_ATTRIBUTES.each { |attr| card[attr.to_s] = article.public_send(attr) }

      cached_user = article.cached_user.as_json
      if cached_user.is_a?(Hash)
        cached_user["cached_base_subscriber"] = cached_user["cached_base_subscriber?"]
        cached_user["cached_community_leader"] = cached_user["cached_community_leader?"]
      end
      card["user"] = cached_user
      card["organization"] = article.cached_organization.as_json if article.cached_organization?
      card["pinned"] = pinned
      card["main_image"] = article.main_image? ? cover_image_url(article.main_image, article.subforem_id) : nil
      card["tag_list"] = article.cached_tag_list_array

      if article.type_of == "status"
        card["body_preview"] = article.body_preview
        card["title_finalized_for_feed"] = article.title_finalized_for_feed
        card["title_for_metadata"] = article.title_for_metadata
      end

      CARD_METHODS.each { |meth| card[meth.to_s] = article.public_send(meth) }

      card["top_comments"] = if article.comments_count.to_i.positive?
                               article.more_inclusive_recent_good_comments.first(3).map do |comment|
                                 decorated = comment.decorate
                                 {
                                   "comment_id" => decorated.id,
                                   "user_id" => decorated.user_id,
                                   "published_timestamp" => decorated.published_timestamp,
                                   "published_at_int" => decorated.published_at_int,
                                   "safe_processed_html" => decorated.safe_processed_html,
                                   "path" => decorated.path,
                                   "username" => decorated.user&.username,
                                   "name" => decorated.user&.name,
                                   "profile_image_90" => decorated.user&.profile_image_90
                                 }
                               end
                             else
                               []
                             end

      card["subforem_logo"] = subforem_logo
      card["context_note"] = article.context_notes.first&.processed_html
      card
    end

    def cover_image_url(main_image, subforem_id)
      Images::Optimizer.call(main_image, width: 1000, subforem_id: subforem_id)
    rescue StandardError
      main_image
    end

    def build_quantized_embeddings(articles)
      return { entries: [] } unless Article.column_names.include?("semantic_embedding")

      cutoff = @now - 30.days
      candidate_ids = articles.filter_map { |a| a.id if a.published_at >= cutoff }
      return { entries: [] } if candidate_ids.empty?

      rows = Article.where(id: candidate_ids)
        .where.not(semantic_embedding: nil)
        .pluck(:id, :semantic_embedding)

      entries = rows.filter_map do |article_id, raw_vec|
        values = raw_vec.to_a.map(&:to_f)
        next if values.empty?

        scale, quantized_bytes = quantize_i8(values)
        next if scale <= 0.0

        {
          id: article_id,
          scale: scale.round(8),
          q: Base64.urlsafe_encode64(quantized_bytes, padding: false)
        }
      end

      { entries: entries }
    end

    def quantize_i8(values)
      max_abs = values.map(&:abs).max.to_f
      return [0.0, ""] if max_abs <= Float::EPSILON

      scale = max_abs / 127.0
      inv_scale = 127.0 / max_abs
      bytes = values.map { |v| (v * inv_scale).round.clamp(-127, 127) }.pack("c*")
      [scale, bytes]
    end
  end
end
