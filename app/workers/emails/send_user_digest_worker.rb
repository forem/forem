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
        smart_summary = if user.last_presence_at.present? && user.last_presence_at >= 3.days.ago
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
      rescue StandardError => e
        Honeybadger.context({ user_id: user.id, article_ids: articles.map(&:id) })
        Honeybadger.notify(e)
      end
    end
  end
end
