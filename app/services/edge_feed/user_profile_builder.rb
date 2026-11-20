module EdgeFeed
  # Builds a compact per-user feed profile (`user:<user_id>`) mirrored to Fastly KV Store
  # for edge custom home-feed evaluation (`forem_core::edge_feed::parse_user_profile_json`).
  class UserProfileBuilder
    EMBEDDING_PRECISION = 6

    def initialize(user:, now: Time.current)
      @user = user
      @now = now
    end

    def build
      activity = @user.user_activity
      setting = @user.setting

      base_profile(activity, setting).merge(activity_profile(activity))
    end

    private

    def base_profile(activity, setting)
      {
        user_id: @user.id,
        targeting_bucket: FeedConfig.targeting_bucket_for(@user, context_type: FeedEvent::CONTEXT_TYPE_HOME),
        has_activity_store: !activity.nil?,
        blocked_user_ids: UserBlock.cached_blocked_ids_for_blocker(@user.id).map(&:to_i),
        hidden_tags: string_list(@user.cached_antifollowed_tag_names),
        hide_fully_autonomous: setting&.hide_fully_autonomous_feed_ai? == true,
        ai_preference: resolve_ai_preference_code(setting),
        languages: resolve_languages,
        precomputed_selections: resolve_precomputed_selections
      }
    end

    def activity_profile(activity)
      alltime_users = activity&.alltime_users
      alltime_orgs = activity&.alltime_organizations

      {
        alltime_users: int_list(alltime_users || @user.cached_following_users_ids),
        alltime_users_from_activity: !alltime_users.nil?,
        recent_users: int_list(activity&.recent_users),
        alltime_organizations: int_list(alltime_orgs || @user.cached_following_organizations_ids),
        alltime_organizations_from_activity: !alltime_orgs.nil?,
        recent_organizations: int_list(activity&.recent_organizations),
        alltime_subforems: int_list(activity&.alltime_subforems),
        recent_subforems: int_list(activity&.recent_subforems),
        recent_tags: string_list(activity&.recent_tags),
        alltime_tags: string_list(activity&.alltime_tags || @user.cached_followed_tag_names),
        recent_labels: string_list(activity&.recent_labels),
        recently_viewed_articles: serialize_recent_views(activity&.recently_viewed_articles),
        interest_embedding: serialize_interest_embedding(activity)
      }
    end

    def int_list(values)
      Array(values).compact_blank.map(&:to_i)
    end

    def string_list(values)
      Array(values).compact_blank.map(&:to_s)
    end

    def resolve_ai_preference_code(setting)
      if setting&.minimize_ai_feed_ai?
        1
      elsif setting&.hide_fully_autonomous_feed_ai?
        2
      else
        0
      end
    end

    def resolve_languages
      langs = if @user.respond_to?(:cached_languages)
                @user.cached_languages
              else
                @user.languages.pluck(:language)
              end
      langs.presence || [I18n.default_locale.to_s]
    end

    def serialize_recent_views(entries)
      Array(entries).filter_map do |entry|
        next unless entry.is_a?(Array) && entry.size >= 2

        article_id = entry[0].to_i
        timestamp = parse_unix_sec(entry[1])
        next unless article_id.positive? && timestamp

        [article_id, timestamp]
      end
    end

    def parse_unix_sec(raw)
      return raw.to_i if raw.is_a?(Integer) || raw.is_a?(Time) || raw.is_a?(ActiveSupport::TimeWithZone)

      Time.zone.parse(raw.to_s)&.to_i
    rescue ArgumentError
      nil
    end

    def resolve_precomputed_selections
      list = RecommendedArticlesList
        .where(user_id: @user.id)
        .where("expires_at > ?", @now)
        .last
      Array(list&.article_ids).compact_blank.map(&:to_i)
    end

    def serialize_interest_embedding(activity)
      return unless activity.respond_to?(:interest_embedding) && activity.interest_embedding.present?

      activity.interest_embedding.to_a.map { |v| v.to_f.round(EMBEDDING_PRECISION) }
    end
  end
end
