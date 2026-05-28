module Articles
  # Re-evaluates `processed_html` for every Article whose stored HTML references
  # a given image source host. Intended as an admin remediation tool when an
  # upstream CDN (or a downstream optimizer like Cloudinary's fetch pipeline)
  # has cached failure responses for assets from that host. Combined with
  # `Images::Optimizer.cloudflare_preferred_host?`, re-rendered articles will
  # bypass the broken pipeline.
  class ReprocessByImageHostWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    BATCH_SIZE = 100

    def perform(host, limit = nil)
      return if host.blank?

      scope = Article.where("processed_html ILIKE ?", "%#{Article.sanitize_sql_like(host)}%")
      scope = scope.limit(limit.to_i) if limit.to_i.positive?

      scope.find_each(batch_size: BATCH_SIZE) do |article|
        original_html = article.processed_html
        article.evaluate_and_update_column_from_markdown
        article.async_bust if original_html != article.processed_html
      end
    end
  end
end
