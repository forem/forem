module Billboards
  # Runs every 10 minutes to titrate BillboardCampaign delivery toward `ideal_daily_impressions`.
  #
  # Efficiency profile:
  # - Fast-exits in 1 indexed query when no active paced campaigns exist.
  # - Loads all campaign billboards in 1 query and aggregates 10-minute impressions across all
  #   paced campaigns in 1 read-replica query scoped by billboard IDs + BRIN `created_at`.
  # - Reads the 7x24 traffic seasonality multiplier from a multi-day Redis cache.
  # - Applies all billboard and campaign lever adjustments in at most 2 batched SQL UPDATEs.
  class TitrateCampaignImpressionsWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })
    sidekiq_options queue: :low_priority, retry: 3

    STATEMENT_TIMEOUT = ENV.fetch("STATEMENT_TIMEOUT_BILLBOARD_TITRATION", 15_000).to_i
    BATCH_UPDATE_SIZE = 250
    THROTTLE_RATE_EPSILON = 1e-6

    def perform
      now = Time.current
      campaigns = active_paced_campaigns(now)
      return clear_throttle_cache if campaigns.empty?

      billboards_by_campaign = load_campaign_billboards(campaigns.map(&:id))
      live_by_campaign, all_billboard_ids = partition_live_billboards(campaigns, billboards_by_campaign, now)
      return clear_throttle_cache if live_by_campaign.empty?

      impressions_by_billboard = fetch_recent_impressions(all_billboard_ids, now)
      traffic_multiplier = Billboards::TrafficProfile.multiplier_for(now)

      billboard_updates, campaign_throttle_updates = compute_updates(
        campaigns, billboards_by_campaign, live_by_campaign, impressions_by_billboard, traffic_multiplier
      )

      persist_updates(billboard_updates, campaign_throttle_updates, now)
      publish_throttle_cache(now)
    rescue ActiveRecord::QueryCanceled => e
      Rails.logger.error("Billboards::TitrateCampaignImpressionsWorker query timeout: #{e.message}")
      raise
    end

    private

    def clear_throttle_cache
      Billboards::CampaignPacing.write_throttled_campaign_rates({})
    end

    def persist_updates(billboard_updates, campaign_throttle_updates, now)
      return if billboard_updates.empty? && campaign_throttle_updates.empty?

      ActiveRecord::Base.transaction do
        batch_update_billboards(billboard_updates, now) if billboard_updates.any?
        batch_update_campaigns(campaign_throttle_updates, now) if campaign_throttle_updates.any?
      end
    end

    def publish_throttle_cache(now)
      Billboards::CampaignPacing.refresh_throttled_campaign_rates_cache!(now: now)
    rescue StandardError => e
      # DB updates already committed atomically; log instead of raising so Sidekiq retries
      # do not re-apply multiplicative weight adjustments to the same 10-minute window.
      Rails.logger.error("Billboards::TitrateCampaignImpressionsWorker cache publish failed: #{e.message}")
    end

    def partition_live_billboards(campaigns, billboards_by_campaign, now)
      live_by_campaign = {}
      all_billboard_ids = []

      campaigns.each do |campaign|
        all_bbs = billboards_by_campaign[campaign.id] || []
        live_bbs = all_bbs.select { |bb| live_billboard?(bb, now) }
        next if live_bbs.empty?

        live_by_campaign[campaign.id] = live_bbs
        all_bbs.each { |bb| all_billboard_ids << bb.id }
      end

      [live_by_campaign, all_billboard_ids]
    end

    def compute_updates(campaigns, billboards_by_campaign, live_by_campaign, impressions_by_billboard,
                        traffic_multiplier)
      billboard_updates = []
      campaign_throttle_updates = []

      campaigns.each do |campaign|
        live_bbs = live_by_campaign[campaign.id]
        next unless live_bbs

        actual_impressions = (billboards_by_campaign[campaign.id] || []).sum do |bb|
          impressions_by_billboard[bb.id].to_i
        end

        result = Billboards::CampaignPacing.calculate_adjustments(
          ideal_daily_impressions: campaign.ideal_daily_impressions,
          actual_impressions: actual_impressions,
          traffic_multiplier: traffic_multiplier,
          current_throttle_rate: campaign.delivery_throttle_rate,
          billboards: live_bbs,
        )

        billboard_updates.concat(result.billboard_updates)
        if (result.throttle_rate - campaign.delivery_throttle_rate.to_f).abs > THROTTLE_RATE_EPSILON
          campaign_throttle_updates << [campaign.id, result.throttle_rate]
        end
      end

      [billboard_updates, campaign_throttle_updates]
    end

    def active_paced_campaigns(now)
      BillboardCampaign
        .with_ideal_daily_impressions
        .where("expires_at IS NULL OR expires_at > ?", now)
        .select(:id, :ideal_daily_impressions, :delivery_throttle_rate)
        .to_a
    end

    def load_campaign_billboards(campaign_ids)
      Billboard
        .where(billboard_campaign_id: campaign_ids)
        .select(:id, :billboard_campaign_id, :approved, :published, :expires_at, :priority, :weight)
        .to_a
        .group_by(&:billboard_campaign_id)
    end

    def live_billboard?(billboard, now)
      billboard.approved && billboard.published && (billboard.expires_at.nil? || billboard.expires_at > now)
    end

    def fetch_recent_impressions(billboard_ids, now)
      return {} if billboard_ids.empty?

      cutoff = now - Billboards::CampaignPacing::WINDOW_DURATION
      counts = {}

      ReadOnlyDatabaseService.with_connection do |conn|
        conn.transaction do
          conn.execute("SET LOCAL statement_timeout TO #{STATEMENT_TIMEOUT}")

          id_list = billboard_ids.uniq.map(&:to_i).join(",")
          sql = <<~SQL.squish
            SELECT display_ad_id, SUM(counts_for)::bigint AS total_impressions
            FROM display_ad_events
            WHERE display_ad_id IN (#{id_list})
              AND category = #{conn.quote(BillboardEvent::CATEGORY_IMPRESSION)}
              AND created_at >= #{conn.quote(cutoff)}
            GROUP BY display_ad_id
          SQL

          conn.execute(sql).each do |row|
            counts[row["display_ad_id"].to_i] = row["total_impressions"].to_i
          end
        end
      end

      counts
    end

    def batch_update_billboards(updates, now)
      conn = ActiveRecord::Base.connection
      quoted_now = conn.quote(now)

      updates.each_slice(BATCH_UPDATE_SIZE) do |slice|
        values_sql = slice.map do |u|
          "(#{u.id.to_i}::bigint, #{Float(u.weight)}::double precision, #{u.priority ? 'TRUE' : 'FALSE'}::boolean)"
        end.join(", ")

        sql = <<~SQL.squish
          UPDATE display_ads AS d
          SET weight = v.weight,
              priority = v.priority,
              updated_at = #{quoted_now}
          FROM (VALUES #{values_sql}) AS v(id, weight, priority)
          WHERE d.id = v.id
            AND EXISTS (
              SELECT 1 FROM billboard_campaigns AS c
              WHERE c.id = d.billboard_campaign_id
                AND c.ideal_daily_impressions > 0
            )
        SQL

        conn.execute(sql)
      end
    end

    def batch_update_campaigns(updates, now)
      conn = ActiveRecord::Base.connection
      quoted_now = conn.quote(now)

      updates.each_slice(BATCH_UPDATE_SIZE) do |slice|
        values_sql = slice.map do |campaign_id, rate|
          "(#{campaign_id.to_i}::bigint, #{Float(rate)}::double precision)"
        end.join(", ")

        sql = <<~SQL.squish
          UPDATE billboard_campaigns AS c
          SET delivery_throttle_rate = v.delivery_throttle_rate,
              updated_at = #{quoted_now}
          FROM (VALUES #{values_sql}) AS v(id, delivery_throttle_rate)
          WHERE c.id = v.id
            AND c.ideal_daily_impressions > 0
        SQL

        conn.execute(sql)
      end
    end
  end
end
