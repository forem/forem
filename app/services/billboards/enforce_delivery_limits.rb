module Billboards
  # Single source of truth for enforcing billboard and campaign expiration dates and delivery caps.
  #
  # Called from three places:
  # 1. `Billboards::EnforceDeliveryLimitsWorker` every 5 minutes (clock-driven expirations and cap safety net).
  # 2. `BillboardCampaign` / `Billboard` `after_commit` callbacks (immediate takedown when limits tighten).
  # 3. `Billboards::DataUpdateWorker` via `Billboard#check_and_handle_delivery_limits` (campaign-wide takedown
  #    as soon as freshly tabulated counts push a billboard or its campaign over a cap).
  class EnforceDeliveryLimits
    BATCH_SIZE = 500

    class << self
      # Sweeps all approved billboards and active campaigns whose expiration date or delivery caps
      # have been reached, unapproving them atomically and purging affected caches.
      #
      # @param now [ActiveSupport::TimeWithZone, Time]
      # @return [Array<Integer>] IDs of billboards transitioned from approved to unapproved
      def sweep!(now: Time.current)
        direct_ids = directly_limited_billboard_ids(now)
        expired_campaign_ids = expired_campaign_ids_with_approved_billboards(now)
        over_cap_campaign_ids = over_cap_campaign_ids_with_approved_billboards
        affected_campaign_ids = (expired_campaign_ids + over_cap_campaign_ids).uniq

        campaign_billboard_ids = if affected_campaign_ids.any?
                                   Billboard.where(billboard_campaign_id: affected_campaign_ids, approved: true).ids
                                 else
                                   []
                                 end

        take_down_billboards!(
          direct_ids + campaign_billboard_ids,
          expired_campaign_ids: expired_campaign_ids,
          now: now,
        )
      end

      # Enforces expiration and delivery caps for an entire campaign, taking down all currently
      # approved member billboards in a single atomic batch.
      #
      # @param campaign [BillboardCampaign, nil]
      # @param now [ActiveSupport::TimeWithZone, Time]
      # @return [Array<Integer>] IDs of billboards transitioned from approved to unapproved
      def enforce_campaign!(campaign, now: Time.current)
        return [] unless campaign&.persisted?
        return [] unless campaign.delivery_limit_reached?(now: now)

        candidate_ids = campaign.billboards.where(approved: true).ids
        expired_ids = campaign.expired?(now: now) ? [campaign.id] : []

        take_down_billboards!(candidate_ids, expired_campaign_ids: expired_ids, now: now)
      end

      # Enforces delivery limits triggered by a single billboard. When the billboard's campaign has
      # expired or hit its combined cap, takes down all approved billboards in that campaign (not
      # only the triggering billboard). Otherwise takes down only the billboard itself if its own
      # expiration or cap has been reached.
      #
      # @param billboard [Billboard, nil]
      # @param now [ActiveSupport::TimeWithZone, Time]
      # @return [Array<Integer>] IDs of billboards transitioned from approved to unapproved
      def enforce_for_billboard!(billboard, now: Time.current)
        return [] unless billboard&.persisted?

        campaign = billboard.billboard_campaign
        if campaign&.delivery_limit_reached?(now: now)
          taken_down_ids = enforce_campaign!(campaign, now: now)
          sync_unapproved_state(billboard) if taken_down_ids.include?(billboard.id)
          return taken_down_ids
        end

        return [] unless billboard.approved? && (billboard.expired?(now: now) || billboard.over_cap?)

        taken_down_ids = take_down_billboards!([billboard.id], now: now)
        sync_unapproved_state(billboard) if taken_down_ids.include?(billboard.id)
        taken_down_ids
      end

      private

      def directly_limited_billboard_ids(now)
        Billboard
          .where(approved: true)
          .where(
            "(expires_at IS NOT NULL AND expires_at <= :now) " \
            "OR (max_impressions_count > 0 AND impressions_count >= max_impressions_count) " \
            "OR (max_clicks_count > 0 AND clicks_count >= max_clicks_count)",
            now: now,
          )
          .ids
      end

      def expired_campaign_ids_with_approved_billboards(now)
        BillboardCampaign
          .joins(:billboards)
          .where(display_ads: { approved: true })
          .where("billboard_campaigns.expires_at IS NOT NULL AND billboard_campaigns.expires_at <= ?", now)
          .distinct
          .ids
      end

      # Sums counts across ALL billboards in each capped campaign (including unapproved/paused ones),
      # and filters via HAVING to campaigns that still have at least one approved billboard left.
      def over_cap_campaign_ids_with_approved_billboards
        BillboardCampaign
          .joins(:billboards)
          .where("billboard_campaigns.max_impressions_count > 0 OR billboard_campaigns.max_clicks_count > 0")
          .group(
            "billboard_campaigns.id",
            "billboard_campaigns.max_impressions_count",
            "billboard_campaigns.max_clicks_count",
          )
          .having(
            "BOOL_OR(COALESCE(display_ads.approved, FALSE)) " \
            "AND (" \
            "(billboard_campaigns.max_impressions_count > 0 " \
            "AND COALESCE(SUM(display_ads.impressions_count), 0) >= billboard_campaigns.max_impressions_count) " \
            "OR (billboard_campaigns.max_clicks_count > 0 " \
            "AND COALESCE(SUM(display_ads.clicks_count), 0) >= billboard_campaigns.max_clicks_count)" \
            ")",
          )
          .ids
      end

      def take_down_billboards!(billboard_ids, expired_campaign_ids: [], now: Time.current)
        ids = billboard_ids.uniq.map(&:to_i)
        taken_down_rows = ids.any? ? atomic_unapprove_billboards(ids, now) : []
        taken_down_ids = taken_down_rows.map { |row| row.fetch(:id) }

        if taken_down_ids.any?
          unpublish_liquid_embed_references(taken_down_ids)
          purge_caches(taken_down_rows)
        end

        refresh_throttle_cache_if_needed(expired_campaign_ids, now)
        taken_down_ids
      end

      def atomic_unapprove_billboards(ids, now)
        conn = ActiveRecord::Base.connection
        quoted_now = conn.quote(now)
        bool_type = ActiveModel::Type::Boolean.new

        ids.each_slice(BATCH_SIZE).flat_map do |slice|
          id_list = slice.map(&:to_i).join(", ")
          sql = <<~SQL.squish
            UPDATE display_ads
            SET approved = FALSE, updated_at = #{quoted_now}
            WHERE id IN (#{id_list}) AND approved = TRUE
            RETURNING id, placement_area, published
          SQL

          conn.exec_query(sql, "Billboard Delivery Limit Takedown").map do |row|
            {
              id: row["id"].to_i,
              placement_area: row["placement_area"],
              published: bool_type.cast(row["published"])
            }
          end
        end
      end

      def unpublish_liquid_embed_references(taken_down_ids)
        updated = LiquidEmbedReference
          .where(record_type: "Billboard", record_id: taken_down_ids, published: true)
          .update_all(published: false)
        LiquidEmbedReference.bust_feed_targets_cache! if updated.positive?
      end

      def purge_caches(taken_down_rows)
        published_rows = taken_down_rows.select { |row| row[:published] }
        return if published_rows.empty?

        table_key = Billboard.table_key
        bust_home = false

        published_rows.each do |row|
          EdgeCache::PurgeByKey.call("#{table_key}/#{row[:id]}")
          bust_home ||= Billboard::HOME_PAGE_PLACEMENTS.include?(row[:placement_area])
        end

        EdgeCache::PurgeByKey.call("main_app_home_page", fallback_paths: "/") if bust_home
      end

      def refresh_throttle_cache_if_needed(expired_campaign_ids, now)
        return if expired_campaign_ids.empty?

        throttled = BillboardCampaign
          .where(id: expired_campaign_ids)
          .where("delivery_throttle_rate < 1.0")
          .exists?
        return unless throttled

        Billboards::CampaignPacing.refresh_throttled_campaign_rates_cache!(now: now)
      rescue StandardError => e
        Rails.logger.error("Billboards::EnforceDeliveryLimits throttle cache refresh failed: #{e.message}")
      end

      def sync_unapproved_state(billboard)
        billboard.assign_attributes(approved: false)
        billboard.clear_attribute_changes(%i[approved])
      end
    end
  end
end
