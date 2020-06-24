module WebMentions
  class SendWebMention
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 15, lock: :until_executing

    def perform(comment_id)
      commentable = Comment.find_by(id: comment_id)&.commentable
      return unless commentable

      return unless commentable.support_webmentions

      canonical_url = commentable.canonical_url
      article_url = ApplicationConfig["APP_DOMAIN"] + commentable.path
      WebMentions::WebMentionHandler.call(canonical_url, article_url)
    end
  end
end
