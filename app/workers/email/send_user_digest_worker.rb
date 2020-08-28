module Email
  class SendUserDigestWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 15, lock: :until_executing

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user&.email_digest_periodic? && user&.registered?

      user_email_heuristic = EmailLogic.new(user).analyze
      return unless user_email_heuristic.should_receive_email?

      articles = user_email_heuristic.articles_to_send
      begin
        DigestMailer.with(user: user, articles: articles).digest_email.deliver_now
      rescue StandardError => e
        Honeybadger.context({ user_id: user.id, article_ids: articles.map(&:id) })
        Honeybadger.notify(e)
      end
    end
  end
end
