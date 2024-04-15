module Emails
  class SendUserDigestWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 15, lock: :until_executing

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user&.notification_setting&.email_digest_periodic? && user&.registered?

      articles = EmailDigestArticleCollector.new(user).articles_to_send
      tags = user.cached_followed_tag_names&.first(12)
      first_billboard = Billboard.for_display(area: "digest_first",
                                              user_id: user.id,
                                              user_tags: tags,
                                              user_signed_in: true)
      second_billboard = Billboard.for_display(area: "digest_second",
                                               user_id: user.id,
                                               user_tags: tags,
                                               user_signed_in: true)
      return unless articles.any?

      begin
        DigestMailer.with(user: user, articles: articles.to_a, billboards: [first_billboard, second_billboard])
          .digest_email.deliver_now
      rescue StandardError => e
        Honeybadger.context({ user_id: user.id, article_ids: articles.map(&:id) })
        Honeybadger.notify(e)
      end
    end
  end
end
