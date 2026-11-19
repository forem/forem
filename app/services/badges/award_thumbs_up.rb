module Badges
  class AwardThumbsUp
    THUMBS_UP_BADGES = {
      100 => "100 Thumbs Up Milestone",
      500 => "500 Thumbs Up Milestone",
      1000 => "1,000 Thumbs Up Milestone",
      5000 => "5,000 Thumbs Up Milestone",
      10_000 => "10,000 Thumbs Up Milestone"
    }.freeze

    MIN_THRESHOLD = THUMBS_UP_BADGES.keys.min
    DEFAULT_LOOKBACK = 7.days
    BATCH_SIZE = 200

    def self.call
      badges_by_threshold = fetch_badges
      return if badges_by_threshold.size != THUMBS_UP_BADGES.size

      user_thumbsup_counts = get_user_thumbsup_counts
      award_for_counts(badges_by_threshold, user_thumbsup_counts)
    end

    # Bounded full-history catch-up that scans eligible users by primary-key chunks
    # and aggregates using the covering `(user_id, reactable_id, reactable_type, category)` index.
    def self.backfill(batch_size: BATCH_SIZE)
      badges_by_threshold = fetch_badges
      return if badges_by_threshold.size != THUMBS_UP_BADGES.size

      User.where("reactions_count >= ?", MIN_THRESHOLD).in_batches(of: batch_size) do |relation|
        counts = count_thumbsup_for_users(relation.ids)
        award_for_counts(badges_by_threshold, counts) if counts.any?
      end
    end

    def self.get_user_thumbsup_counts(since: DEFAULT_LOOKBACK.ago, batch_size: BATCH_SIZE)
      candidate_ids = if since
                        Reaction.where(category: "thumbsup", reactable_type: "Article")
                          .where("created_at >= ?", since)
                          .distinct
                          .pluck(:user_id)
                      else
                        User.where("reactions_count >= ?", MIN_THRESHOLD).ids
                      end
      return {} if candidate_ids.empty?

      counts = {}
      candidate_ids.each_slice(batch_size) do |batch_user_ids|
        counts.merge!(count_thumbsup_for_users(batch_user_ids))
      end

      counts.sort_by { |_, count| -count }.to_h
    end

    def self.count_thumbsup_for_users(user_ids)
      return {} if user_ids.empty?

      Reaction.where(user_id: user_ids, category: "thumbsup", reactable_type: "Article")
        .group(:user_id)
        .having("COUNT(*) >= ?", MIN_THRESHOLD)
        .count
    end

    def self.award_for_counts(badges_by_threshold, user_thumbsup_counts)
      return if user_thumbsup_counts.empty?

      single_award_badge_ids = badges_by_threshold.values.reject(&:allow_multiple_awards).map(&:id)
      messages_by_threshold = THUMBS_UP_BADGES.keys.index_with { |threshold| generate_message(threshold: threshold) }

      user_thumbsup_counts.keys.each_slice(BATCH_SIZE) do |batch_user_ids|
        existing_pairs = if single_award_badge_ids.any?
                           BadgeAchievement.where(user_id: batch_user_ids, badge_id: single_award_badge_ids)
                             .pluck(:user_id, :badge_id)
                             .to_set
                         else
                           Set.new
                         end

        batch_user_ids.each do |user_id|
          count = user_thumbsup_counts[user_id]
          THUMBS_UP_BADGES.each_key do |threshold|
            break unless count >= threshold

            badge = badges_by_threshold[threshold]
            next unless badge
            next if !badge.allow_multiple_awards && existing_pairs.include?([user_id, badge.id])

            BadgeAchievement.create(
              user_id: user_id,
              badge_id: badge.id,
              rewarding_context_message_markdown: messages_by_threshold[threshold],
            )
          end
        end
      end
    end

    def self.fetch_badges
      Badge.select(:id, :title, :allow_multiple_awards)
        .where(title: THUMBS_UP_BADGES.values)
        .index_by { |badge| THUMBS_UP_BADGES.key(badge.title) }
    end

    def self.fetch_badge_ids
      fetch_badges.transform_values(&:id)
    end

    def self.generate_message(threshold:)
      I18n.t("services.badges.thumbs_up", count: threshold)
    end
  end
end
