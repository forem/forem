module Notifications
  class BustCaches
    attr_reader :user, :notifiable_id, :notifiable_type

    FINDERS = {
      "Article" => Article,
      "Comment" => Comment
    }.freeze

    def self.call(...)
      new(...).call
    end

    def initialize(user:, notifiable: nil, notifiable_id: nil, notifiable_type: nil)
      @user = user
      @notifiable_id = notifiable_id
      @notifiable_type = notifiable_type
      @notifiable = notifiable
    end

    def call
      Rails.cache.delete_matched(activity_published_article_key)
      Rails.cache.delete_matched(comment_box_key)
    end

    def notifiable
      @notifiable ||= FINDERS.fetch(notifiable_type).find(notifiable_id)
    end

    def last_user_reaction
      @last_user_reaction ||= @user.reactions.last&.id
    end

    def activity_published_article_key
      return unless effected_article_id

      "*activity-published-article-reactions-#{last_user_reaction}-*-#{effected_article_id}"
    end

    def comment_box_key
      "*comment-box-#{last_user_reaction}-*"
    end

    def effected_article_id
      return notifiable.id if notifiable.is_a?(Article)

      notifiable.commentable_id if notifiable.commentable_type == "Article"
    end
  end
end
