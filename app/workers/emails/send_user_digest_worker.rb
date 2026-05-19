module Emails
  class SendUserDigestWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 15, lock: :until_executing

    def perform(user_id, force_send = false)
      user = User.find_by(id: user_id)
      return unless user&.registered?

      if !force_send && !user.notification_setting&.email_digest_periodic?
        return
      end

      articles = EmailDigestArticleCollector.new(user, force_send: force_send).articles_to_send
      return unless articles.any?

      articles_needing_summary = articles.select { |a| a.ai_summary.blank? && a.ai_summary_generated_at.nil? }

      if articles_needing_summary.any? && defined?(Ai::Base::DEFAULT_KEY) && Ai::Base::DEFAULT_KEY.present?
        full_articles = Article.where(id: articles_needing_summary.map(&:id)).index_by(&:id)

        articles_needing_summary.each do |article|
          full_article = full_articles[article.id]
          next unless full_article

          # Use an atomic cache lock to prevent multiple digest jobs from hammering the AI API for the same article simultaneously
          # Lock for 15 minutes to allow digest processing to finish without overlapping retries
          cache_key = "article_summary_attempt:#{article.id}"
          lock_acquired = Rails.cache.write(cache_key, true, expires_in: 15.minutes, unless_exist: true)
          next unless lock_acquired

          begin
            Ai::ArticleSummaryGenerator.new(full_article).call

            # Assign the generated summary to the partial record so the email template can use it
            article.ai_summary = full_article.reload.ai_summary
          rescue StandardError => e
            Rails.logger.warn("Failed to generate summary for article #{article.id} in digest: #{e.message}")
            Honeybadger.notify(e) if defined?(Honeybadger)
          end
        end
      end

      tags = user.cached_followed_tag_names&.first(12)
      first_billboard = Billboard.for_display(area: "digest_first",
                                              user_id: user.id,
                                              user_tags: tags,
                                              user_signed_in: true)
      paired_billboard = Billboard.where(published: true,
                                         approved: true,
                                         placement_area: "digest_second",
                                         prefer_paired_with_billboard_id: first_billboard&.id).last

      second_billboard = paired_billboard || Billboard.for_display(area: "digest_second",
                                                                   user_id: user.id,
                                                                   user_tags: tags,
                                                                   user_signed_in: true)

      begin
        smart_summary = if user.last_presence_at.present? && user.last_presence_at >= 3.days.ago && FeatureFlag.enabled?(:digest_smart_summary)
                          Ai::EmailDigestSummary.new(articles.to_a).generate
                        end

        DigestMailer.with(
          user: user,
          articles: articles.to_a,
          billboards: [first_billboard, second_billboard],
          smart_summary: smart_summary,
        )
          .digest_email.deliver_now

        # Track billboard impressions with relaxed durability — these are
        # low-priority analytics writes that don't need synchronous WAL flush.
        if first_billboard.present? || second_billboard.present?
          event_params = { user_id: user.id, context_type: "email", category: "impression" }
          ApplicationRecord.with_synchronous_commit_off do
            BillboardEvent.create(event_params.merge(billboard_id: first_billboard.id)) if first_billboard.present?
            BillboardEvent.create(event_params.merge(billboard_id: second_billboard.id)) if second_billboard.present?
          end
        end
      rescue Net::SMTPSyntaxError, Net::SMTPFatalError => e
        Rails.logger.warn("Failed to send digest to user #{user.id} due to SMTP syntax/fatal error: #{e.message}")
      rescue StandardError => e
        Honeybadger.context({ user_id: user.id, article_ids: articles.map(&:id) })
        Honeybadger.notify(e)
      end
    end
  end
end
