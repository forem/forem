module Organizations
  class TrackPromotionalBillboardImpressionsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 3

    CACHE_KEY = "paused_promotional_billboard_organization_ids".freeze
    CACHE_EXPIRY = 15.minutes

    def perform
      # Find all organizations that have promotional billboard tracking enabled
      organizations = Organization.where("ideal_daily_promoted_billboard_impressions > 0")

      paused_organization_ids = []

      organizations.find_each do |organization|
        # Skip if organization is invalid or missing required fields
        next unless organization.persisted?
        next if organization.ideal_daily_promoted_billboard_impressions.nil? || organization.ideal_daily_promoted_billboard_impressions <= 0

        begin
          # Calculate past 24 hours impressions for this organization
          past_24_hours_impressions = calculate_past_24_hours_impressions(organization)

          # Ensure we have a valid integer (handle nil/negative values)
          past_24_hours_impressions = [past_24_hours_impressions.to_i, 0].max

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

      # Cache the list of paused organization IDs (ensure it's always an array)
      Rails.cache.write(CACHE_KEY, paused_organization_ids.uniq, expires_in: CACHE_EXPIRY)
    end

    private

    def calculate_past_24_hours_impressions(organization)
      return 0 unless organization&.id

      # Count impressions from billboard events in the past 24 hours
      # Join billboard_events -> billboards -> organizations
      # Only count events from billboards that belong to this organization
      cutoff_time = 24.hours.ago

      BillboardEvent
        .impressions
        .joins(billboard: :organization)
        .where(organizations: { id: organization.id })
        .where("display_ad_events.created_at > ?", cutoff_time)
        .sum(:counts_for) || 0
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

