module DataUpdateScripts
  class BackfillBillboardAndUnresolvedEmbedReferences
    BATCH_SIZE = 250
    UNRESOLVED_TAGS = %w[link post feed org devcomment].freeze

    def run
      sync_and_refresh_billboards
      enqueue_unresolved_reference_syncs
      LiquidEmbedReference.bust_feed_targets_cache!
    end

    private

    def sync_and_refresh_billboards
      sync_worker = SyncLiquidEmbedReferencesWorker.new
      now = Time.current

      Billboard
        .where(render_mode: :forem_markdown)
        .where("body_markdown LIKE :pattern OR minimized_body_markdown LIKE :pattern", pattern: "%{%")
        .includes(:creator)
        .find_each do |billboard|
          sync_worker.perform("Billboard", billboard.id)

          is_active = billboard.approved? &&
            billboard.published? &&
            (billboard.expires_at.nil? || billboard.expires_at > now)
          billboard.refresh_embedded_markdown! if is_active
        end
    end

    def enqueue_unresolved_reference_syncs
      scope = LiquidEmbedReference.where(tag_name: UNRESOLVED_TAGS, referenced_id: nil)

      internal_host = Settings::General.app_domain.presence ||
        ApplicationConfig["APP_DOMAIN"].presence ||
        default_url_host

      if internal_host.present?
        clean_host = internal_host.to_s.sub(%r{\Ahttps?://}, "").delete_prefix("www.")
        sanitized_host = ActiveRecord::Base.sanitize_sql_like(clean_host)
        scope = scope.or(
          LiquidEmbedReference
            .where(tag_name: "embed", referenced_id: nil)
            .where("url ILIKE ?", "%#{sanitized_host}%"),
        )
      end

      pairs = scope.where.not(record_type: "Billboard").distinct.pluck(:record_type, :record_id)
      page_pairs = Page.where("body_markdown LIKE ?", "%{%").ids.map { |id| ["Page", id] }

      (pairs + page_pairs).uniq.each_slice(BATCH_SIZE) do |batch|
        SyncLiquidEmbedReferencesWorker.perform_bulk(batch)
      end
    end

    def default_url_host
      URI.parse(URL.url).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
