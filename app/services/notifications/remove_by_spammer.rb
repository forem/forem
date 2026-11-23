# remove notifications created for spammer actions:
# follow user, create comments, create articles
module Notifications
  class RemoveBySpammer
    def self.call(...)
      new(...).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return unless user

      comment_ids = user.comment_ids
      article_ids = user.article_ids
      mention_ids = Mention.where(mentionable_type: "Comment", mentionable_id: comment_ids)
        .or(Mention.where(mentionable_type: "Article", mentionable_id: article_ids))
        .ids

      remove("Follow", user.follow_ids)
      remove("Comment", comment_ids)
      remove("Mention", mention_ids)
      remove("Article", article_ids, action: "Published")
    end

    private

    attr_reader :user

    def remove(notifiable_type, notifiable_ids, action: nil)
      scope = Notification.where(notifiable_type: notifiable_type, notifiable_id: notifiable_ids)
      scope = scope.where(action: action) if action
      return unless scope.delete_all.positive?

      Notifications::SyncEvents.removed(
        notifiable_type: notifiable_type,
        notifiable_ids: notifiable_ids,
        action: action,
        all_actions: action.nil?,
        reason: "spam",
      )
    end
  end
end
