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

      Notification.where(notifiable_type: "Follow", notifiable_id: user.follow_ids).delete_all
      Notification.where(notifiable_type: "Comment", notifiable_id: user.comment_ids).delete_all
      Notification.where(
        notifiable_type: "Mention",
        notifiable_id: Mention.where(mentionable_type: "Comment", mentionable_id: user.comment_ids)
                              .or(Mention.where(mentionable_type: "Article", mentionable_id: user.article_ids))
                              .select(:id),
      ).delete_all
      Notification.where(notifiable_type: "Article", action: "Published", notifiable_id: user.article_ids).delete_all
    end

    private

    attr_reader :user
  end
end
