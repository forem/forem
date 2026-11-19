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

      internal_hosts.each do |host|
        sanitized_host = ActiveRecord::Base.sanitize_sql_like(host)
        pattern = "%#{sanitized_host}%"
        scope = scope.or(
          LiquidEmbedReference
            .where(tag_name: "embed", referenced_id: nil)
            .where("url ILIKE :pattern OR options ILIKE :pattern", pattern: pattern),
        )
      end

      pairs = scope.where.not(record_type: "Billboard").distinct.pluck(:record_type, :record_id)
      (pairs + template_and_markdown_page_pairs).uniq.each_slice(BATCH_SIZE) do |batch|
        SyncLiquidEmbedReferencesWorker.perform_bulk(batch)
      end
    end

    def internal_hosts
      candidates = [
        Settings::General.app_domain,
        ApplicationConfig["APP_DOMAIN"],
        default_url_host,
      ]
      candidates.concat(Subforem.cached_domains) if defined?(Subforem) && Subforem.respond_to?(:cached_domains)

      candidates.compact_blank.filter_map do |raw|
        raw.to_s.strip.downcase.sub(%r{\Ahttps?://}, "").delete_prefix("www.").chomp("/").presence
      end.uniq
    end

    def template_and_markdown_page_pairs
      direct_ids = Page.where("body_markdown LIKE ?", "%{%").ids
      template_ids = Page
        .joins(:page_template)
        .where("page_templates.body_markdown LIKE :pattern OR pages.template_data::text LIKE :pattern", pattern: "%{%")
        .ids

      (direct_ids + template_ids).uniq.map { |id| ["Page", id] }
    end

    def default_url_host
      URI.parse(URL.url).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
