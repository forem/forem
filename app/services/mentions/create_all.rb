module Mentions
  # This class creates mentions + associated notifications for Articles and Comments.
  # This class will check to see if there are any @-mentions in the post, and will
  # create the associated mentions inline if necessary.
  class CreateAll
    def self.call(...)
      new(...).call
    end

    def initialize(notifiable)
      @notifiable = notifiable
    end

    # Creates Mention records and notifications for the notifiable, respecting per-post and hourly rate limits.
    def call
      return if notifiable_flagged_or_author_restricted?

      with_author_mention_lock do
        mentioned_users = users_mentioned_in_text_excluding_author
        if notifiable.user.present?
          mentioned_users = mentioned_users.first(allowed_mentions_count)
        end

        delete_mentions_removed_from_notifiable_text(mentioned_users)
        create_mentions_for(mentioned_users)
      end
    end

    private

    # Acquires the author's mention rate limit lock when an author is present.
    def with_author_mention_lock(&block)
      return yield if notifiable.user.blank?

      notifiable.user.rate_limiter.with_user_mention_lock(&block)
    end

    # Calculates the maximum number of mentions allowed for this notifiable under both per-post and hourly limits.
    def allowed_mentions_count
      rate_limiter = notifiable.user.rate_limiter
      remaining_hourly = [
        rate_limiter.hourly_mention_limit - rate_limiter.recent_mention_count(exclude_notifiable: notifiable),
        0,
      ].max
      [rate_limiter.max_mentions_per_post, remaining_hourly].min
    end

    # Returns true if the author is spam/suspended or the notifiable has an active mascot spam reaction.
    def notifiable_flagged_or_author_restricted?
      return true if notifiable.user&.spam_or_suspended?

      Spam::Handler.active_spam_reaction_for?(reactable: notifiable)
    end

    def users_mentioned_in_text_excluding_author
      mentioned_usernames = extract_usernames_from_mentions_in_text

      collect_existing_users(mentioned_usernames)
        .then do |existing_mentioned_users|
          reject_notifiable_author(existing_mentioned_users)
        end
    end

    def collect_existing_users(usernames)
      User.registered.where(username: usernames)
    end

    # Creates mentions for the given users and records the created count in the author's hourly mention cache.
    def create_mentions_for(users)
      created_count = users.count do |user|
        mention = create_mention_for(user)
        mention&.persisted?
      end
      notifiable.user&.rate_limiter&.track_mentions(created_count, notifiable: notifiable) if created_count.positive?
    end

    def extract_usernames_from_mentions_in_text
      ForemNative.extract_mentioned_usernames(notifiable.processed_html) ||
        legacy_extract_usernames_from_mentions_in_text
    end

    def legacy_extract_usernames_from_mentions_in_text
      # The "mentioned-user" css is added by Html::Parser#user_link_if_exists
      doc = Nokogiri::HTML(notifiable.processed_html)

      # Remove any mentions that are embedded within any liquid tags
      non_liquid_tag_mentions = doc.css(".mentioned-user").reject do |tag|
        tag.ancestors(".liquid-comment").any? ||
          tag.ancestors("[class^=ltag]").any? ||
          tag.ancestors("[class*=' ltag']").any?
      end

      non_liquid_tag_mentions.map { |link| link.text.delete("@").downcase }
    end

    def reject_notifiable_author(users)
      users.reject { |user| authored_by?(user, notifiable) }
    end

    def authored_by?(user, notifiable)
      user.id == notifiable.user_id
    end

    def delete_mentions_removed_from_notifiable_text(users)
      mentions = notifiable.mentions.where.not(user_id: users).destroy_all
      Notification.remove_all(notifiable_ids: mentions.map(&:id), notifiable_type: "Mention") if mentions.present?
    end

    def user_has_comment_notifications?(user)
      user.notifications.exists?(notifiable_id: notifiable.id, notifiable_type: "Comment")
    end

    def create_mention_for(user)
      # Do not create additional notifications for being mentioned in a comment.
      if notifiable.is_a?(Comment) && user_has_comment_notifications?(user)
        return
      end

      # Re-runs (e.g. Articles::Updater on edit) must not re-notify users who were already mentioned.
      return if Mention.exists?(user_id: user.id, mentionable_id: notifiable.id,
                                mentionable_type: notifiable.class.name)

      # The mentionable_type is the model that created the mention, the user is the user to be mentioned.
      mention = Mention.create(user_id: user.id, mentionable_id: notifiable.id,
                               mentionable_type: notifiable.class.name)

      # Never send a notification for a mention that failed to save; log it so failures are visible.
      unless mention.persisted?
        Rails.logger.warn(
          "Mentions::CreateAll could not create mention for user #{user.id} on " \
          "#{notifiable.class.name} #{notifiable.id}: #{mention.errors.full_messages.to_sentence}",
        )
        return mention
      end

      # If notifiable is an Article, we need to create the notification for the mention immediately so
      # that the notification exists in the database before we attempt to create other Article-related notifications.
      # However, if notifiable is a Comment, we can create the notification for the mention in the background.
      case notifiable
      when Article
        Notification.send_mention_notification_without_delay(mention)
      when Comment
        Notification.send_mention_notification(mention)
      end

      mention
    end

    attr_reader :notifiable
  end
end
