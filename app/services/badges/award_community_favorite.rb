module Badges
  class AwardCommunityFavorite
    MILESTONES = [2, 4, 8, 16, 32, 64].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(favoritable:, favoriter:)
      @favoritable = favoritable
      @favoriter = favoriter
    end

    def call
      return if favoritable.user_id.blank?

      user = favoritable.user
      gems_count = count_user_gems(user)

      if MILESTONES.include?(gems_count)
        award_milestone_badge(user, gems_count)
      else
        send_progress_notification(user, gems_count)
      end
    end

    private

    attr_reader :favoritable, :favoriter

    def count_user_gems(user)
      sql = <<~SQL.squish
        SELECT (SELECT COUNT(*) FROM articles WHERE user_id = :user_id AND favorited_by_user_id IS NOT NULL) +
               (SELECT COUNT(*) FROM comments WHERE user_id = :user_id AND favorited_by_user_id IS NOT NULL)
      SQL
      ActiveRecord::Base.connection.select_value(
        ActiveRecord::Base.sanitize_sql([sql, { user_id: user.id }]),
      ).to_i
    end

    def award_milestone_badge(user, count)
      return unless (badge_id = find_badge_id(count))

      achievement = BadgeAchievement.create(
        user_id: user.id,
        badge_id: badge_id,
        rewarder_id: favoriter.id,
        rewarding_context_message_markdown: milestone_message(count),
      )
      user.touch if achievement.valid?

      achievement
    end

    def send_progress_notification(user, count)
      message_markdown = progress_message(count)
      parsed_markdown = MarkdownProcessor::Parser.new(message_markdown)
      html_message = ActionController::Base.helpers.sanitize(
        parsed_markdown.finalize,
        tags: MarkdownProcessor::AllowedTags::BADGE_ACHIEVEMENT_CONTEXT_MESSAGE,
        attributes: MarkdownProcessor::AllowedAttributes::BADGE_ACHIEVEMENT_CONTEXT_MESSAGE,
      )

      json_data = {
        message: html_message,
        user: Notifications.user_data(favoriter),
      }
      if comment?
        json_data[:comment] = Notifications.comment_data(favoritable)
      else
        json_data[:article] = Notifications.article_data(favoritable)
      end

      Notification.create(
        user_id: user.id,
        notifiable_id: favoritable.id,
        notifiable_type: favoritable.class.name,
        action: "Favorited",
        json_data: json_data,
      )
    end

    def find_badge_id(count)
      Badge.id_for_slug(badge_slug(count)) || Badge.id_for_slug("community-favorite-#{count}")
    end

    def badge_slug(count)
      "community-favorite-#{count}-gems"
    end

    def next_milestone_for(count)
      MILESTONES.find { |m| m > count }
    end

    def milestone_message(count)
      next_milestone = next_milestone_for(count)
      key_prefix = comment? ? "comment" : "article"

      if next_milestone
        I18n.t(
          "services.badges.award_community_favorite.#{key_prefix}_milestone_message",
          count: count,
          next_count: next_milestone,
          url: favoritable_url,
        )
      else
        I18n.t(
          "services.badges.award_community_favorite.#{key_prefix}_max_milestone_message",
          count: count,
          url: favoritable_url,
        )
      end
    end

    def progress_message(count)
      key_prefix = comment? ? "comment" : "article"

      if count <= 1
        I18n.t(
          "services.badges.award_community_favorite.#{key_prefix}_first_gem_notification",
          url: favoritable_url,
        )
      else
        next_milestone = next_milestone_for(count)
        if next_milestone
          I18n.t(
            "services.badges.award_community_favorite.#{key_prefix}_progress_notification",
            count: count,
            next_count: next_milestone,
            url: favoritable_url,
          )
        else
          I18n.t(
            "services.badges.award_community_favorite.#{key_prefix}_max_progress_notification",
            count: count,
            url: favoritable_url,
          )
        end
      end
    end

    def favoritable_url
      comment? ? URL.comment(favoritable) : URL.article(favoritable)
    end

    def comment?
      favoritable.is_a?(Comment)
    end
  end
end
