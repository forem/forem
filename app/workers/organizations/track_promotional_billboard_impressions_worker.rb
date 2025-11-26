module Organizations
  class TrackPromotionalBillboardImpressionsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 3

    CACHE_KEY = "paused_promotional_billboard_organization_ids".freeze
    CACHE_EXPIRY = 15.minutes
    STATEMENT_TIMEOUT = ENV.fetch("STATEMENT_TIMEOUT_BULK_DELETE", 30_000).to_i

    def perform
      paused_organization_ids = []

      # Use read-only database if available to avoid impacting main database
      ReadOnlyDatabaseService.with_connection do |conn|
        conn.transaction do
          # Set statement timeout for the entire transaction
          conn.execute("SET LOCAL statement_timeout TO #{STATEMENT_TIMEOUT}")

          # Fetch all impressions in a single aggregate query instead of N+1
          impressions_by_org = fetch_impressions_by_organization(conn)

          # Find all organizations that have promotional billboard tracking enabled
          organizations = Organization.where("ideal_daily_promoted_billboard_impressions > 0")

          organizations.find_each do |organization|
            # Skip if organization is invalid or missing required fields
            next unless organization.persisted?
            next if organization.ideal_daily_promoted_billboard_impressions.nil? ||
                    organization.ideal_daily_promoted_billboard_impressions <= 0

            begin
              # Get past 24 hours impressions from the pre-fetched data
              past_24_hours_impressions = [impressions_by_org[organization.id].to_i, 0].max

              # Update the organization's past 24 hours impressions
              organization.update_column(:past_24_hours_promoted_billboard_impressions, past_24_hours_impressions)

              # Check if we should pause promotional billboards
              # Only pause if impressions exceed 2x the ideal daily amount
              ideal_daily = organization.ideal_daily_promoted_billboard_impressions.to_i
              should_pause = ideal_daily > 0 && past_24_hours_impressions > (2 * ideal_daily)

              # Update the paused status
              organization.update_column(:currently_paused_promotional_billboards, should_pause)

              paused_organization_ids << organization.id if should_pause
            rescue StandardError => e
              # Log error but continue processing other organizations
              Rails.logger.error(
                "Error processing organization #{organization.id} in TrackPromotionalBillboardImpressionsWorker: #{e.message}"
              )
              Rails.logger.error(e.backtrace.join("\n"))
              next
            end
          end
        end
      end

      # Cache the list of paused organization IDs (ensure it's always an array)
      Rails.cache.write(CACHE_KEY, paused_organization_ids.uniq, expires_in: CACHE_EXPIRY)
    rescue ActiveRecord::QueryCanceled => e
      Rails.logger.error("TrackPromotionalBillboardImpressionsWorker query timeout: #{e.message}")
      # Re-raise to trigger Sidekiq retry
      raise
    end

    private

    def fetch_impressions_by_organization(conn)
      cutoff_time = 24.hours.ago

      # Single aggregate query to get all impressions grouped by organization
      # This avoids N+1 queries and is much more efficient
      sql = <<~SQL.squish
        SELECT billboards.organization_id, SUM(display_ad_events.counts_for) as total_impressions
        FROM display_ad_events
        INNER JOIN display_ads AS billboards ON billboards.id = display_ad_events.display_ad_id
        WHERE display_ad_events.category = 'impression'
          AND display_ad_events.created_at > '#{conn.quote_string(cutoff_time.iso8601)}'
          AND billboards.organization_id IS NOT NULL
        GROUP BY billboards.organization_id
      SQL

      result = conn.execute(sql)
      result.each_with_object({}) do |row, hash|
        hash[row["organization_id"]] = row["total_impressions"].to_i
      end
    end

    # Class method to get cached paused organization IDs
    def self.paused_organization_ids
      cached_ids = Rails.cache.read(CACHE_KEY)
      # Ensure we always return an array of integers
      return [] if cached_ids.nil? || cached_ids.empty?

      Array(cached_ids).map(&:to_i).compact
    end
  end
end

