class FeedConfig < ApplicationRecord
  LOW_IMPRESSION_COUNT = 25
  TOP_POOL_LIMIT = 15

  BUCKET_ALL = "all".freeze
  BUCKET_FEED_NEW_USER = "feed_new_user".freeze
  BUCKET_FEED_CASUAL_USER = "feed_casual_user".freeze
  BUCKET_FEED_ACTIVE_USER = "feed_active_user".freeze
  BUCKET_FEED_POWER_USER = "feed_power_user".freeze
  BUCKET_DIGEST = "digest".freeze

  FEED_TARGETING_BUCKETS = [
    BUCKET_FEED_NEW_USER,
    BUCKET_FEED_CASUAL_USER,
    BUCKET_FEED_ACTIVE_USER,
    BUCKET_FEED_POWER_USER,
  ].freeze

  NON_ALL_TARGETING_BUCKETS = (FEED_TARGETING_BUCKETS + [BUCKET_DIGEST]).freeze
  TARGETING_BUCKETS = ([BUCKET_ALL] + NON_ALL_TARGETING_BUCKETS).freeze

  enum :targeting_bucket, {
    all: 0,
    feed_new_user: 1,
    feed_casual_user: 2,
    feed_active_user: 3,
    feed_power_user: 4,
    digest: 5
  }, prefix: :bucket, validate: true

  POWER_USER_MIN_COMMENT_DAYS = 4
  ACTIVE_USER_MIN_PAGEVIEW_DAYS = 3
  ACTIVITY_LOOKBACK = 7.days

  has_many :feed_events, dependent: :nullify

  validates :targeting_bucket, inclusion: { in: TARGETING_BUCKETS }, presence: true

  ARCHIVE_TOP_LIMIT = 1000
  ARCHIVE_AGE_THRESHOLD = 2.days

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :for_targeting_bucket, ->(bucket) { where(targeting_bucket: bucket) }

  def self.targeting_bucket_for(user = nil, context_type: nil)
    return BUCKET_DIGEST if context_type.to_s.in?([FeedEvent::CONTEXT_TYPE_EMAIL, BUCKET_DIGEST])
    return BUCKET_FEED_CASUAL_USER unless user

    if power_user?(user)
      BUCKET_FEED_POWER_USER
    elsif active_user?(user)
      BUCKET_FEED_ACTIVE_USER
    elsif new_user?(user)
      BUCKET_FEED_NEW_USER
    else
      BUCKET_FEED_CASUAL_USER
    end
  end

  def self.power_user?(user)
    return false unless user&.id

    cutoff = ACTIVITY_LOOKBACK.ago
    if user.respond_to?(:last_comment_at) && user.last_comment_at.present? && user.last_comment_at < cutoff
      return false
    end

    Comment.where(user_id: user.id)
      .where("created_at >= ?", cutoff)
      .distinct
      .count(Arel.sql("DATE(created_at)")) >= POWER_USER_MIN_COMMENT_DAYS
  end

  def self.active_user?(user)
    return false unless user&.id

    cutoff = ACTIVITY_LOOKBACK.ago
    if user.respond_to?(:user_activity)
      recent_views = user.user_activity&.recently_viewed_articles
      if recent_views.present?
        activity_days = recent_views.filter_map do |entry|
          timestamp = entry.is_a?(Array) ? entry[1] : nil
          next unless timestamp

          dt = timestamp.to_datetime
          dt.to_date if dt >= cutoff
        rescue StandardError
          nil
        end.uniq.size

        return true if activity_days >= ACTIVE_USER_MIN_PAGEVIEW_DAYS
      end
    end

    PageView.where(user_id: user.id)
      .where("created_at >= ?", cutoff)
      .distinct
      .count(Arel.sql("DATE(created_at)")) >= ACTIVE_USER_MIN_PAGEVIEW_DAYS
  end

  def self.new_user?(user)
    return false unless user

    signup_time = (user.respond_to?(:registered_at) && user.registered_at) ||
      (user.respond_to?(:created_at) && user.created_at)
    signup_time.present? && signup_time >= ACTIVITY_LOOKBACK.ago
  end

  def self.archive_stale_configs!
    top_ids = TARGETING_BUCKETS.flat_map do |bucket|
      active
        .where(targeting_bucket: bucket)
        .order(feed_success_score: :desc, id: :desc)
        .limit(ARCHIVE_TOP_LIMIT)
        .ids
    end

    active
      .where("created_at < ?", ARCHIVE_AGE_THRESHOLD.ago)
      .where.not(id: top_ids)
      .in_batches(of: 1000)
      .update_all(archived: true, updated_at: Time.current)
  end

  def self.select_for_feed(preferred_id: nil, user: nil, context_type: nil, targeting_bucket: nil)
    if preferred_id.present?
      preferred = active.find_by(id: preferred_id)
      return preferred if preferred
    end

    bucket = resolve_selection_bucket(user: user, context_type: context_type, targeting_bucket: targeting_bucket)
    if bucket.present? && bucket != BUCKET_ALL
      select_for_targeted_bucket(bucket)
    else
      select_from_scope(active)
    end
  end

  def self.resolve_selection_bucket(user: nil, context_type: nil, targeting_bucket: nil)
    if targeting_bucket.present? && TARGETING_BUCKETS.include?(targeting_bucket.to_s)
      targeting_bucket.to_s
    elsif user.present? || context_type.present?
      targeting_bucket_for(user, context_type: context_type)
    end
  end
  private_class_method :resolve_selection_bucket

  def self.select_from_scope(scope)
    roll = rand(100)
    selected = if roll < 20 # 20% of the time, prioritize the newest low-impression configs
                 scope
                   .where("feed_impressions_count < ?", LOW_IMPRESSION_COUNT)
                   .order(created_at: :desc)
                   .limit(TOP_POOL_LIMIT)
                   .sample
               elsif roll < 25 # 5% of the time, pick a random config so none are completely starved
                 scope.order("RANDOM()").limit(1).first
               end

    proven_pool = scope.where("feed_impressions_count >= ?", LOW_IMPRESSION_COUNT)
    tested_pool = scope.where("feed_impressions_count > 0")

    selected ||
      proven_pool.order(feed_success_score: :desc).limit(rand(1..TOP_POOL_LIMIT)).sample ||
      tested_pool.order(feed_success_score: :desc).limit(rand(1..TOP_POOL_LIMIT)).sample ||
      scope.order(feed_success_score: :desc).limit(rand(1..TOP_POOL_LIMIT)).sample ||
      scope.first_or_create
  end
  private_class_method :select_from_scope

  def self.select_for_targeted_bucket(bucket)
    bucket_scope = active.where(targeting_bucket: bucket)
    fallback_scope = active.where(targeting_bucket: [bucket, BUCKET_ALL])
    bucket_int = targeting_buckets.fetch(bucket.to_s)
    bucket_priority_sql = Arel.sql("CASE WHEN targeting_bucket = #{bucket_int.to_i} THEN 0 ELSE 1 END ASC")

    roll = rand(100)
    selected = if roll < 20 # 20% of the time, prioritize the newest low-impression configs in this bucket
                 bucket_low_imp = bucket_scope.where("feed_impressions_count < ?", LOW_IMPRESSION_COUNT)
                 fallback_low_imp = fallback_scope.where("feed_impressions_count < ?", LOW_IMPRESSION_COUNT)
                 low_imp_scope = bucket_low_imp.exists? ? bucket_low_imp : fallback_low_imp
                 low_imp_scope
                   .order(created_at: :desc)
                   .limit(TOP_POOL_LIMIT)
                   .sample
               elsif roll < 25 # 5% of the time, pick a random config so none are completely starved
                 (bucket_scope.exists? ? bucket_scope : fallback_scope).order("RANDOM()").limit(1).first
               end

    proven_fallback = fallback_scope.where("feed_impressions_count >= ?", LOW_IMPRESSION_COUNT)
    tested_fallback = fallback_scope.where("feed_impressions_count > 0")

    selected ||
      proven_fallback.order(bucket_priority_sql, feed_success_score: :desc).limit(rand(1..TOP_POOL_LIMIT)).sample ||
      tested_fallback.order(bucket_priority_sql, feed_success_score: :desc).limit(rand(1..TOP_POOL_LIMIT)).sample ||
      fallback_scope.order(bucket_priority_sql, feed_success_score: :desc).limit(rand(1..TOP_POOL_LIMIT)).sample ||
      bucket_scope.first_or_create
  end
  private_class_method :select_for_targeted_bucket

  def score_sql(user)
    activity_store = user.user_activity

    recent_pageviews_count = activity_store&.recently_viewed_articles&.count { |_, timestamp| timestamp.to_datetime > 24.hours.ago } || 0
    user_follow_ids = (activity_store&.alltime_users&.first(200) || user.cached_following_users_ids) + (activity_store&.recent_users&.compact || [])
    organization_follow_ids = (activity_store&.alltime_organizations&.first(200) || user.cached_following_organizations_ids) + (activity_store&.recent_organizations&.compact || [])
    subforem_follow_ids = activity_store&.alltime_subforems || []
    recent_tags_count = rand(recent_tag_count_min..recent_tag_count_max) if recent_tag_count_min.positive? && recent_tag_count_max.positive?
    all_time_tags_count = rand(all_time_tag_count_min..all_time_tag_count_max) if all_time_tag_count_min.positive? && all_time_tag_count_max.positive?
    tag_names = activity_store&.relevant_tags(recent_tags_count || 5, all_time_tags_count || 5) || user.cached_followed_tag_names
    label_names = activity_store&.recent_labels || []

    activity_tracked_pageview_time = activity_store&.recently_viewed_articles&.second
    time_of_second_latest_page_view = activity_tracked_pageview_time ? activity_tracked_pageview_time[1].to_datetime : 4.days.ago
    lookback_window = time_of_second_latest_page_view - 18.hours

    terms = []

    terms << "(articles.feed_success_score * #{feed_success_weight})" if feed_success_weight.positive?
    terms << "(articles.comment_score * #{comment_score_weight})" if comment_score_weight.positive?
    terms << "(articles.score * #{score_weight})" if score_weight.positive?

    if organization_follow_weight.positive?
      org_ids = organization_follow_ids.compact_blank
      org_ids_str = org_ids.empty? ? "-1" : org_ids.join(',')
      terms << "(CASE WHEN articles.organization_id IN (#{org_ids_str}) THEN #{organization_follow_weight} ELSE 0 END)"
    end

    if user_follow_weight.positive?
      user_ids = user_follow_ids.compact_blank
      user_ids_str = user_ids.empty? ? "-1" : user_ids.join(',')
      terms << "(CASE WHEN articles.user_id IN (#{user_ids_str}) THEN #{user_follow_weight} ELSE 0 END)"
    end

    if follow_status_weight.positive?
      user_ids = user_follow_ids.compact_blank
      user_ids_str = user_ids.empty? ? "-1" : user_ids.join(',')
      terms << "(CASE WHEN articles.type_of = 1 AND articles.user_id IN (#{user_ids_str}) THEN #{follow_status_weight} ELSE 0 END)"
    end

    if tag_follow_weight.positive? && tag_names.present?
      tag_condition = if ENV["OPTIMIZED_FEED_TAGS_QUERY"] == "true"
                        tags_overlap_sql = tag_names.first(rand(20..40)).map { |t| self.class.connection.quote(t) }.join(',')
                        "CASE WHEN articles.tags_array && ARRAY[#{tags_overlap_sql}]::text[] THEN #{tag_follow_weight} ELSE 0 END"
                      else
                        "CASE WHEN " + tag_names.first(24).map { |tag|
                          "articles.cached_tag_list ~ '[[:<:]]#{tag}[[:>:]]'"
                        }.join(' OR ') + " THEN #{tag_follow_weight} ELSE 0 END"
                      end
      terms << "(#{tag_condition})"
    end

    if subforem_follow_weight.positive? &&
      RequestStore.store[:subforem_id].present? &&
      RequestStore.store[:subforem_id] == RequestStore.store[:root_subforem_id]
      subforem_ids = subforem_follow_ids.compact_blank
      subforem_ids_str = subforem_ids.empty? ? "-1" : subforem_ids.join(',')
      terms << "(CASE WHEN articles.subforem_id IN (#{subforem_ids_str}) THEN #{subforem_follow_weight} ELSE 0 END)"
    end

    ## Labels slightly different because we can use native Postgres array operators
    if label_match_weight.positive? && label_names.present?
      labels_str = label_names.map { |l| self.class.connection.quote(l) }.join(',')
      label_condition = "CASE WHEN articles.cached_label_list && ARRAY[#{labels_str}]::varchar[] THEN #{label_match_weight} ELSE 0 END"
      terms << "(#{label_condition})"
    end

    terms << "((1.0 / (1.0 + (EXTRACT(epoch FROM (NOW() - articles.published_at)) / 3600.0))) * #{recency_weight})" if recency_weight.positive?
    terms << "((1.0 / (1.0 + (EXTRACT(epoch FROM (NOW() - articles.last_comment_at)) / 3600.0))) * #{comment_recency_weight})" if comment_recency_weight.positive?

    if lookback_window_weight.positive?
      terms << "(CASE WHEN articles.published_at BETWEEN '#{lookback_window.utc.to_fs(:db)}' AND '#{time_of_second_latest_page_view.utc.to_fs(:db)}' THEN #{lookback_window_weight} ELSE 0 END)"
    end

    if precomputed_selections_weight.positive?
      precomputed_selections = RecommendedArticlesList.where(user_id: user.id)
                                                       .where("expires_at > ?", Time.current)
                                                       .last&.article_ids || []
      selections = precomputed_selections.compact_blank
      if selections.any?
        terms << "(CASE WHEN articles.id IN (#{selections.join(',')}) THEN #{precomputed_selections_weight} ELSE 0 END)"
      end
    end

    if recent_article_suppression_rate.positive? && activity_store
      # Compute recently viewed article IDs using the page_views table.
      recent_ids = activity_store.recently_viewed_articles.map(&:first).compact_blank
      recent_ids_str = recent_ids.any? ? recent_ids.join(',') : "-1"
      terms << "(CASE WHEN articles.id IN (#{recent_ids_str}) THEN -#{recent_article_suppression_rate} ELSE 0 END)"
    end

    if published_today_weight.positive?
      published_since = 24.hours.ago.utc.to_fs(:db)
      terms << "(CASE WHEN articles.published_at >= '#{published_since}' THEN #{published_today_weight} ELSE 0 END)"
    end

    if general_past_day_bonus_weight.positive?
      published_since = 24.hours.ago.utc.to_fs(:db)
      terms << "(CASE WHEN articles.published_at >= '#{published_since}' THEN #{general_past_day_bonus_weight} ELSE 0 END)"
    end

    if recently_active_past_day_bonus_weight.positive? && recent_pageviews_count.positive?
      bonus_value = recently_active_past_day_bonus_weight * recent_pageviews_count
      published_since = 24.hours.ago.utc.to_fs(:db)
      terms << "(CASE WHEN articles.published_at >= '#{published_since}' THEN #{bonus_value} ELSE 0 END)"
    end

    if recent_subforem_weight.positive? &&
      activity_store&.recent_subforems&.any? &&
      RequestStore.store[:root_subforem_id].present? &&
      RequestStore.store[:subforem_id] == RequestStore.store[:root_subforem_id]
      ids     = activity_store.recent_subforems.compact_blank
      if ids.any?
        arr_sql = "ARRAY[#{ids.join(',')}]::bigint[]"

        terms << <<~SQL.squish
          (
            CASE
              WHEN articles.subforem_id = ANY(#{arr_sql})
              THEN #{recent_subforem_weight}
                   * COALESCE(
                       cardinality(
                         array_positions(#{arr_sql}, articles.subforem_id)
                       ),
                       0
                     )
              ELSE 0
            END
          )
        SQL
      end
    end

    # Additional weights
    if semantic_similarity_weight.positive? && activity_store&.respond_to?(:interest_embedding) && activity_store&.interest_embedding.present?
      embedding_values = activity_store.interest_embedding.to_a
      embedding_literal = "[#{embedding_values.join(',')}]"
      embedding_sql = self.class.connection.quote(embedding_literal)
      semantic_similarity_published_since = self.class.connection.quote(30.days.ago.utc.to_fs(:db))
      terms << <<~SQL.squish
        (
          CASE
            WHEN articles.semantic_embedding IS NOT NULL
              AND articles.published_at >= #{semantic_similarity_published_since}
            THEN (1 - (articles.semantic_embedding <=> #{embedding_sql})) * #{semantic_similarity_weight}
            ELSE 0
          END
        )
      SQL
    end

    if ai_disclosure_matching_weight.positive?
      user_setting = user.respond_to?(:setting) ? user.setting : nil
      if user_setting&.minimize_ai_feed_ai?
        terms << "(CASE WHEN articles.ai_disclosure_level = 3 THEN -#{ai_disclosure_matching_weight} WHEN articles.ai_disclosure_level = 5 THEN -#{ai_disclosure_matching_weight * 2} ELSE 0 END)"
      elsif user_setting&.hide_fully_autonomous_feed_ai?
        terms << "(CASE WHEN articles.ai_disclosure_level = 3 THEN -#{ai_disclosure_matching_weight} ELSE 0 END)"
      end
    end

    if autonomous_ai_penalty_weight.positive?
      terms << "(CASE WHEN articles.ai_disclosure_level = 5 THEN -#{autonomous_ai_penalty_weight} ELSE 0 END)"
    end

    terms << "(CASE WHEN articles.featured = TRUE THEN #{featured_weight} ELSE 0 END)" if featured_weight.positive?
    terms << "(CASE WHEN articles.favorited_by_user_id IS NOT NULL THEN #{favorited_weight} ELSE 0 END)" if favorited_weight.positive?
    terms << "(CASE WHEN articles.type_of = 1 THEN #{status_weight} ELSE 0 END)" if status_weight.positive?
    terms << "(- (articles.clickbait_score * #{clickbait_score_weight}))" if clickbait_score_weight.positive?
    terms << "(articles.compellingness_score * #{compellingness_score_weight})" if compellingness_score_weight.positive?
    if language_match_weight.positive? && score_weight.positive?
      languages = if user.respond_to?(:cached_languages)
                    user.cached_languages
                  elsif user.respond_to?(:languages) && user.languages.respond_to?(:loaded?) && user.languages.loaded?
                    user.languages.map(&:language)
                  elsif user.respond_to?(:languages)
                    user.languages.pluck(:language)
                  else
                    []
                  end
      languages = [I18n.default_locale.to_s] if languages.blank?
      terms << "(CASE WHEN articles.language IN ('#{languages.join("','")}') THEN #{language_match_weight} ELSE 0 END)"
    end
    if randomness_weight.positive?
      # Injecting a dynamic Ruby scope guarantees row shuffling uniquely per-request without sacrificing query planners dynamically!
      terms << "((CASE WHEN articles.id IS NOT NULL THEN MOD((articles.id * 137 + #{rand(10000)}), 1000) / 1000.0 ELSE 0 END) * #{randomness_weight})"
    end

    total_expression = terms.any? ? terms.join(" + ") : "0"

    <<~SQL.squish
      (#{total_expression})
    SQL
  end

  def create_slightly_modified_clone!(user: nil, context_type: nil, targeting_bucket: nil)
    clone = dup
    clone.comment_recency_weight = comment_recency_weight * rand(0.9..1.1)
    clone.comment_score_weight = comment_score_weight * rand(0.9..1.1)
    clone.feed_success_weight = feed_success_weight * rand(0.9..1.1)
    clone.label_match_weight = label_match_weight * rand(0.9..1.1)
    clone.semantic_similarity_weight = semantic_similarity_weight * rand(0.9..1.1)
    clone.lookback_window_weight = lookback_window_weight * rand(0.9..1.1)
    clone.organization_follow_weight = organization_follow_weight * rand(0.9..1.1)
    clone.precomputed_selections_weight = precomputed_selections_weight * rand(0.9..1.1)
    clone.recency_weight = recency_weight * rand(0.9..1.1)
    clone.score_weight = score_weight * rand(0.9..1.1)
    clone.tag_follow_weight = tag_follow_weight * rand(0.9..1.1)
    clone.user_follow_weight = user_follow_weight * rand(0.9..1.1)
    clone.randomness_weight = randomness_weight * rand(0.9..1.1)
    clone.recent_article_suppression_rate = recent_article_suppression_rate * rand(0.9..1.1)
    clone.published_today_weight = published_today_weight * rand(0.9..1.1)
    clone.general_past_day_bonus_weight = general_past_day_bonus_weight * rand(0.9..1.1)
    clone.recently_active_past_day_bonus_weight = recently_active_past_day_bonus_weight * rand(0.9..1.1)
    clone.featured_weight = featured_weight * rand(0.9..1.1)
    clone.favorited_weight = favorited_weight * rand(0.9..1.1)
    clone.status_weight = status_weight * rand(0.9..1.1)
    clone.follow_status_weight = follow_status_weight * rand(0.9..1.1)
    clone.clickbait_score_weight = clickbait_score_weight * rand(0.9..1.1)
    clone.compellingness_score_weight = compellingness_score_weight * rand(0.9..1.1)
    clone.language_match_weight = language_match_weight * rand(0.9..1.1)
    clone.recent_subforem_weight = recent_subforem_weight * rand(0.9..1.1)
    clone.subforem_follow_weight = subforem_follow_weight * rand(0.9..1.1)
    clone.recent_page_views_shuffle_weight = recent_page_views_shuffle_weight * rand(0.9..1.1)
    clone.ai_disclosure_matching_weight = ai_disclosure_matching_weight * rand(0.9..1.1)
    clone.autonomous_ai_penalty_weight = autonomous_ai_penalty_weight * rand(0.9..1.1)
    clone.recent_tag_count_min = [recent_tag_count_min + rand(-1..1), 0].max if recent_tag_count_min.positive?
    clone.recent_tag_count_max = [recent_tag_count_max + rand(-1..1), 12].min if recent_tag_count_max.positive?
    clone.recent_tag_count_max = clone.recent_tag_count_min if clone.recent_tag_count_max < clone.recent_tag_count_min
    clone.all_time_tag_count_min = [all_time_tag_count_min + rand(-1..1), 0].max if all_time_tag_count_min.positive?
    clone.all_time_tag_count_max = [all_time_tag_count_max + rand(-1..1), 12].min if all_time_tag_count_max.positive?
    clone.all_time_tag_count_max = clone.all_time_tag_count_min if clone.all_time_tag_count_max < clone.all_time_tag_count_min
    clone.targeting_bucket = cloned_targeting_bucket(
      user: user,
      context_type: context_type,
      requested_bucket: targeting_bucket,
    )
    clone.feed_impressions_count = 0
    clone.feed_success_score = 0.0
    clone.archived = false
    clone.tap(&:save)
  end

  private

  def cloned_targeting_bucket(user: nil, context_type: nil, requested_bucket: nil)
    if requested_bucket.present? && NON_ALL_TARGETING_BUCKETS.include?(requested_bucket.to_s)
      requested_bucket.to_s
    elsif context_type.present? || user.present?
      self.class.targeting_bucket_for(user, context_type: context_type)
    elsif NON_ALL_TARGETING_BUCKETS.include?(targeting_bucket)
      targeting_bucket
    else
      BUCKET_FEED_CASUAL_USER
    end
  end
end
