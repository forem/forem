module WebMentions
  class CheckWebMentionSupport
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 15, lock: :until_executing

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      webmention_status = WebMentions::WebMentionHandler.new(article.canonical_url).accepts_webmention?
      article.update(support_webmentions: webmention_status)
    end
  end
end
