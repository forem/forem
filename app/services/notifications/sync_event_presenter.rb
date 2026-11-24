module Notifications
  # The display fields Notifications::SyncEvents sends for a notification: a
  # stable kind, the actor, and a plain-text line and absolute
  # link, so a consumer can list notifications without Forem's templates. Reads
  # json_data only, so it works on unsaved rows built for a fan-out.
  class SyncEventPresenter
    KINDS = {
      %w[Article Published] => "new_post",
      %w[Article CoAuthor] => "co_author",
      %w[Article subforem_change] => "subforem_change",
      ["Comment", nil] => "comment",
      ["Mention", nil] => "mention",
      ["BadgeAchievement", nil] => "badge",
      ["TagAdjustment", nil] => "tag_adjustment",
      ["AdminNotification", nil] => "admin"
    }.freeze
    ACTORLESS_KINDS = %w[
      badge milestone welcome event_reminder tag_adjustment subforem_change org_deverification
    ].freeze
    VARIANT_KINDS = %w[event_reminder tag_adjustment co_author_invitation org_invitation].freeze
    TEXT_LIMIT = 300
    FALLBACK_PATH = "/notifications".freeze

    def initialize(notification)
      @notification = notification
      @data = (notification.json_data || {}).deep_stringify_keys
    end

    def to_h
      {
        "kind" => kind,
        "actor" => actor,
        "text" => text,
        "url" => url
      }
    end

    def kind
      @kind ||= KINDS.fetch([notification.notifiable_type, action]) { kind_from_action }
    end

    private

    attr_reader :notification, :data

    delegate :action, to: :notification

    def kind_from_action
      return "reaction" if action == "Reaction"
      return "follow" if action == "Follow"
      return "community_favorite" if action == "Favorited"
      return "milestone" if action.to_s.start_with?("Milestone::")

      case notification.notifiable_type
      when "Broadcast" then "welcome"
      when "Event" then "event_reminder"
      when "CoAuthorInvitation" then "co_author_invitation"
      when "OrganizationMembership" then "org_invitation"
      when "Organization" then action.to_s.start_with?("Deverification::") ? "org_deverification" : "other"
      else "other"
      end
    end

    def aggregated_count
      siblings = case kind
                 when "reaction" then data.dig("reaction", "aggregated_siblings")
                 when "follow" then data["aggregated_siblings"]
                 end
      [Array.wrap(siblings).size, 1].max
    end

    def actor
      user = data["user"]
      return if user.blank? || ACTORLESS_KINDS.include?(kind)

      {
        "id" => user["id"],
        "username" => user["username"],
        "name" => user["name"],
        "profile_image_url" => user["profile_image_90"]
      }
    end

    def title
      raw = data.dig("admin_notification", "title") ||
        data.dig("article", "title") ||
        data.dig("comment", "commentable", "title") ||
        data.dig("reaction", "reactable", "title") ||
        data.dig("broadcast", "title") ||
        data.dig("event", "title")
      plain(raw)
    end

    def text
      line = I18n.with_locale(I18n.default_locale) { render_text }
      plain(line).to_s.truncate(TEXT_LIMIT)
    end

    def render_text
      case kind
      when "reaction" then aggregated_text("reaction.#{reactable_key}")
      when "follow" then aggregated_text("follow")
      when "milestone" then milestone_text
      when "welcome", "admin" then title || localized("other")
      when *VARIANT_KINDS then localized("#{kind}.#{variant}")
      else localized(kind)
      end
    end

    def variant
      case kind
      when "event_reminder" then action == "reminder_1_hour" ? "hour" : "day"
      when "tag_adjustment" then data["adjustment_type"] == "removal" ? "removal" : "addition"
      when "co_author_invitation" then action == "Accepted" ? "accepted" : "invited"
      when "org_invitation" then actor ? "by_user" : "generic"
      end
    end

    def aggregated_text(key)
      others = aggregated_count - 1
      others.zero? ? localized("#{key}.solo") : localized("#{key}.others", count: others)
    end

    def reactable_key
      data.dig("reaction", "reactable_type") == "Comment" ? "comment" : "article"
    end

    def milestone_text
      _prefix, type, count = action.split("::")
      localized("milestone.#{type == 'Reaction' ? 'reaction' : 'view'}", count: count.to_i)
    end

    def localized(key, **options)
      I18n.t(
        "services.notifications.sync_events.#{key}",
        actor: data.dig("user", "name").presence || data.dig("user", "username"),
        title: title,
        organization: data.dig("organization", "name"),
        badge: data.dig("badge_achievement", "badge", "title"),
        tag: data["tag_name"],
        community: data.dig("new_subforem", "name"),
        **options,
      )
    end

    def url
      domain = notification.subforem_id && Subforem.cached_id_to_domain_hash[notification.subforem_id]
      URL.url(path, domain)
    end

    def path
      path = case kind
             when "follow", "badge" then data.dig("user", "path")
             when "reaction" then data.dig("reaction", "reactable", "path")
             when "org_invitation", "org_deverification" then data.dig("organization", "path")
             when "admin" then data.dig("admin_notification", "url")
             else data.dig("comment", "path") || data.dig("article", "path")
             end
      path.presence || FALLBACK_PATH
    end

    def plain(value)
      value.to_s.squish.presence
    end
  end
end
