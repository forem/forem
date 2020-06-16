module WebMentions
  class SendWebMention
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 15, lock: :until_executing

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment

      return unless comment.commentable.support_webmentions

      canonical_url = comment.commentable.canonical_url
      article_url = ApplicationConfig["APP_DOMAIN"] + comment.commentable.path
      WebMentions::WebMentionHandler.call(canonical_url, article_url)
    end
  end
end
