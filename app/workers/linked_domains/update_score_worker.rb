module LinkedDomains
  class UpdateScoreWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(domain_id)
      domain = LinkedDomain.find_by(id: domain_id)
      return unless domain

      # Check if updated in the last hour
      time_since_update = Time.current - (domain.score_updated_at || 10.years.ago)
      
      if time_since_update < 1.hour
        # Schedule it to run exactly when the 1 hour cooldown expires.
        # The `on_conflict: :replace` lock ensures we only have one future job enqueued at a time.
        self.class.perform_in(1.hour - time_since_update, domain_id)
        return
      end

      # We sum the score of all unique articles that link to this domain
      # Note: This net_score currently aggregates scores from Article records only. 
      # Links appearing exclusively in Comment bodies do not contribute to this score.
      article_ids = WebpageReference.where(linked_domain_id: domain.id, record_type: "Article")
                                    .select(:record_id)
                                    .distinct
      total_score = Article.where(id: article_ids).sum(:score)

      domain.update(net_score: total_score, score_updated_at: Time.current)
    end
  end
end
