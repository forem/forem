module Billboards
  # Fast, bounded aggregate queries backing the Billboard & Campaign admin dashboards.
  #
  # Efficiency guarantees:
  # - Overview KPI strips run in a single aggregate SQL pass over `display_ads` / `billboard_campaigns`
  #   without loading markdown/HTML payloads or scanning `display_ad_events`.
  # - Campaign index rollups batch all displayed campaign IDs into one `GROUP BY` query (zero N+1).
  # - Daily trend series queries `display_ad_events` via `ReadOnlyDatabaseService` with a strict
  #   time window, billboard ID list, and `SET LOCAL statement_timeout`, degrading gracefully on timeout.
  class AdminAnalytics
    STATEMENT_TIMEOUT = ENV.fetch("STATEMENT_TIMEOUT_BILLBOARD_ADMIN_ANALYTICS", 8_000).to_i
    EXPIRING_SOON_WINDOW = 48.hours
    DEFAULT_SERIES_DAYS = 14

    OverviewSummary = Data.define(
      :total_count,
      :live_count,
      :draft_or_paused_count,
      :expired_count,
      :capped_count,
      :prioritized_live_count,
      :expiring_soon_count,
      :total_impressions,
      :total_clicks,
      :live_impressions,
      :live_clicks,
      :live_seconds_visible,
      :total_campaigns_count,
      :active_campaigns_count,
    )

    CampaignsOverview = Data.define(
      :total_campaigns,
      :active_campaigns,
      :paced_campaigns,
      :throttled_campaigns,
      :ended_campaigns,
      :total_live_billboards,
      :total_impressions,
      :total_clicks,
      :total_seconds_visible,
    )

    CampaignRollup = Data.define(
      :billboards_count,
      :live_billboards_count,
      :prioritized_count,
      :impressions_count,
      :clicks_count,
      :seconds_visible,
      :min_weight,
      :max_weight,
    ) do
      def ctr
        return 0.0 unless impressions_count.positive?

        clicks_count.to_f / impressions_count
      end

      def avg_seconds_visible
        return 0.0 unless impressions_count.positive?

        seconds_visible.to_f / impressions_count
      end
    end

    EMPTY_ROLLUP = CampaignRollup.new(
      billboards_count: 0,
      live_billboards_count: 0,
      prioritized_count: 0,
      impressions_count: 0,
      clicks_count: 0,
      seconds_visible: 0,
      min_weight: nil,
      max_weight: nil,
    ).freeze

    DailyPoint = Data.define(:date, :impressions, :clicks, :conversions) do
      def ctr
        return 0.0 unless impressions.positive?

        clicks.to_f / impressions
      end
    end

    DailySeriesResult = Data.define(:points, :past_24h_impressions, :past_24h_clicks, :timed_out) do
      def total_impressions
        points.sum(&:impressions)
      end

      def total_clicks
        points.sum(&:clicks)
      end

      def total_conversions
        points.sum(&:conversions)
      end

      def max_daily_impressions
        points.map(&:impressions).max.to_i
      end
    end

    PlacementBreakdownRow = Data.define(
      :placement_area,
      :label,
      :billboards_count,
      :live_count,
      :impressions_count,
      :clicks_count,
      :impression_share,
    ) do
      def ctr
        return 0.0 unless impressions_count.positive?

        clicks_count.to_f / impressions_count
      end
    end

    class << self
      def overview_summary(now: Time.current)
        conn = ActiveRecord::Base.connection
        q_now = conn.quote(now)
        q_soon = conn.quote(now + EXPIRING_SOON_WINDOW)

        live_cond = <<~SQL.squish
          d.approved = TRUE AND d.published = TRUE
          AND (d.expires_at IS NULL OR d.expires_at > #{q_now})
          AND (c.id IS NULL OR c.expires_at IS NULL OR c.expires_at > #{q_now})
        SQL

        expired_cond = <<~SQL.squish
          (d.expires_at IS NOT NULL AND d.expires_at <= #{q_now})
          OR (c.id IS NOT NULL AND c.expires_at IS NOT NULL AND c.expires_at <= #{q_now})
        SQL

        capped_cond = <<~SQL.squish
          (d.max_impressions_count > 0 AND COALESCE(d.impressions_count, 0) >= d.max_impressions_count)
          OR (d.max_clicks_count > 0 AND COALESCE(d.clicks_count, 0) >= d.max_clicks_count)
        SQL

        expiring_soon_cond = <<~SQL.squish
          (#{live_cond})
          AND (
            (d.expires_at IS NOT NULL AND d.expires_at <= #{q_soon})
            OR (c.id IS NOT NULL AND c.expires_at IS NOT NULL AND c.expires_at <= #{q_soon})
          )
        SQL

        sql = <<~SQL.squish
          SELECT
            COALESCE(SUM(1), 0)::bigint AS total_count,
            COALESCE(SUM(CASE WHEN #{live_cond} THEN 1 ELSE 0 END), 0)::bigint AS live_count,
            COALESCE(SUM(CASE WHEN NOT (#{live_cond}) AND NOT (#{expired_cond}) AND NOT (#{capped_cond}) THEN 1 ELSE 0 END), 0)::bigint AS draft_or_paused_count,
            COALESCE(SUM(CASE WHEN #{expired_cond} THEN 1 ELSE 0 END), 0)::bigint AS expired_count,
            COALESCE(SUM(CASE WHEN #{capped_cond} THEN 1 ELSE 0 END), 0)::bigint AS capped_count,
            COALESCE(SUM(CASE WHEN (#{live_cond}) AND d.priority = TRUE THEN 1 ELSE 0 END), 0)::bigint AS prioritized_live_count,
            COALESCE(SUM(CASE WHEN #{expiring_soon_cond} THEN 1 ELSE 0 END), 0)::bigint AS expiring_soon_count,
            COALESCE(SUM(COALESCE(d.impressions_count, 0)), 0)::bigint AS total_impressions,
            COALESCE(SUM(COALESCE(d.clicks_count, 0)), 0)::bigint AS total_clicks,
            COALESCE(SUM(CASE WHEN #{live_cond} THEN COALESCE(d.impressions_count, 0) ELSE 0 END), 0)::bigint AS live_impressions,
            COALESCE(SUM(CASE WHEN #{live_cond} THEN COALESCE(d.clicks_count, 0) ELSE 0 END), 0)::bigint AS live_clicks,
            COALESCE(SUM(CASE WHEN #{live_cond} THEN COALESCE(d.seconds_visible, 0) ELSE 0 END), 0)::bigint AS live_seconds_visible,
            COUNT(DISTINCT CASE WHEN #{live_cond} THEN d.billboard_campaign_id END)::bigint AS active_campaigns_count
          FROM display_ads d
          LEFT JOIN billboard_campaigns c ON c.id = d.billboard_campaign_id
        SQL

        row = conn.select_one(sql) || {}
        total_campaigns = BillboardCampaign.count

        OverviewSummary.new(
          total_count: row["total_count"].to_i,
          live_count: row["live_count"].to_i,
          draft_or_paused_count: row["draft_or_paused_count"].to_i,
          expired_count: row["expired_count"].to_i,
          capped_count: row["capped_count"].to_i,
          prioritized_live_count: row["prioritized_live_count"].to_i,
          expiring_soon_count: row["expiring_soon_count"].to_i,
          total_impressions: row["total_impressions"].to_i,
          total_clicks: row["total_clicks"].to_i,
          live_impressions: row["live_impressions"].to_i,
          live_clicks: row["live_clicks"].to_i,
          live_seconds_visible: row["live_seconds_visible"].to_i,
          total_campaigns_count: total_campaigns,
          active_campaigns_count: row["active_campaigns_count"].to_i,
        )
      end

      def campaigns_overview_summary(now: Time.current)
        conn = ActiveRecord::Base.connection
        q_now = conn.quote(now)

        expired_cond = "(c.expires_at IS NOT NULL AND c.expires_at <= #{q_now})"
        capped_cond = <<~SQL.squish
          (c.max_impressions_count > 0 AND COALESCE(r.impressions_count, 0) >= c.max_impressions_count)
          OR (c.max_clicks_count > 0 AND COALESCE(r.clicks_count, 0) >= c.max_clicks_count)
        SQL
        ended_cond = "(#{expired_cond} OR #{capped_cond})"
        active_cond = "(NOT #{ended_cond} AND COALESCE(r.live_billboards_count, 0) > 0)"

        sql = <<~SQL.squish
          WITH rollups AS (
            SELECT
              billboard_campaign_id,
              COUNT(*)::bigint AS billboards_count,
              SUM(CASE
                WHEN approved = TRUE AND published = TRUE AND (expires_at IS NULL OR expires_at > #{q_now})
                THEN 1 ELSE 0
              END)::bigint AS live_billboards_count,
              COALESCE(SUM(impressions_count), 0)::bigint AS impressions_count,
              COALESCE(SUM(clicks_count), 0)::bigint AS clicks_count,
              COALESCE(SUM(seconds_visible), 0)::bigint AS seconds_visible
            FROM display_ads
            WHERE billboard_campaign_id IS NOT NULL
            GROUP BY billboard_campaign_id
          )
          SELECT
            COUNT(*)::bigint AS total_campaigns,
            COALESCE(SUM(CASE WHEN #{active_cond} THEN 1 ELSE 0 END), 0)::bigint AS active_campaigns,
            COALESCE(SUM(CASE WHEN NOT #{ended_cond} AND c.ideal_daily_impressions > 0 THEN 1 ELSE 0 END), 0)::bigint AS paced_campaigns,
            COALESCE(SUM(CASE WHEN NOT #{ended_cond} AND c.ideal_daily_impressions > 0 AND c.delivery_throttle_rate < 1.0 THEN 1 ELSE 0 END), 0)::bigint AS throttled_campaigns,
            COALESCE(SUM(CASE WHEN #{ended_cond} THEN 1 ELSE 0 END), 0)::bigint AS ended_campaigns,
            COALESCE(SUM(CASE WHEN NOT #{ended_cond} THEN COALESCE(r.live_billboards_count, 0) ELSE 0 END), 0)::bigint AS total_live_billboards,
            COALESCE(SUM(COALESCE(r.impressions_count, 0)), 0)::bigint AS total_impressions,
            COALESCE(SUM(COALESCE(r.clicks_count, 0)), 0)::bigint AS total_clicks,
            COALESCE(SUM(COALESCE(r.seconds_visible, 0)), 0)::bigint AS total_seconds_visible
          FROM billboard_campaigns c
          LEFT JOIN rollups r ON r.billboard_campaign_id = c.id
        SQL

        row = conn.select_one(sql) || {}

        CampaignsOverview.new(
          total_campaigns: row["total_campaigns"].to_i,
          active_campaigns: row["active_campaigns"].to_i,
          paced_campaigns: row["paced_campaigns"].to_i,
          throttled_campaigns: row["throttled_campaigns"].to_i,
          ended_campaigns: row["ended_campaigns"].to_i,
          total_live_billboards: row["total_live_billboards"].to_i,
          total_impressions: row["total_impressions"].to_i,
          total_clicks: row["total_clicks"].to_i,
          total_seconds_visible: row["total_seconds_visible"].to_i,
        )
      end

      def campaign_rollups(campaign_ids, now: Time.current)
        ids = Array(campaign_ids).uniq.map(&:to_i).select(&:positive?)
        return {} if ids.empty?

        conn = ActiveRecord::Base.connection
        q_now = conn.quote(now)

        sql = <<~SQL.squish
          SELECT
            d.billboard_campaign_id,
            COUNT(*)::bigint AS billboards_count,
            SUM(CASE
              WHEN d.approved = TRUE AND d.published = TRUE
                AND (d.expires_at IS NULL OR d.expires_at > #{q_now})
                AND (c.expires_at IS NULL OR c.expires_at > #{q_now})
              THEN 1 ELSE 0
            END)::bigint AS live_billboards_count,
            SUM(CASE WHEN d.priority = TRUE THEN 1 ELSE 0 END)::bigint AS prioritized_count,
            COALESCE(SUM(d.impressions_count), 0)::bigint AS impressions_count,
            COALESCE(SUM(d.clicks_count), 0)::bigint AS clicks_count,
            COALESCE(SUM(d.seconds_visible), 0)::bigint AS seconds_visible,
            MIN(d.weight)::double precision AS min_weight,
            MAX(d.weight)::double precision AS max_weight
          FROM display_ads d
          INNER JOIN billboard_campaigns c ON c.id = d.billboard_campaign_id
          WHERE d.billboard_campaign_id IN (#{ids.join(', ')})
          GROUP BY d.billboard_campaign_id
        SQL

        conn.exec_query(sql, "Billboard Campaign Rollups").each_with_object({}) do |row, hash|
          hash[row["billboard_campaign_id"].to_i] = CampaignRollup.new(
            billboards_count: row["billboards_count"].to_i,
            live_billboards_count: row["live_billboards_count"].to_i,
            prioritized_count: row["prioritized_count"].to_i,
            impressions_count: row["impressions_count"].to_i,
            clicks_count: row["clicks_count"].to_i,
            seconds_visible: row["seconds_visible"].to_i,
            min_weight: row["min_weight"]&.to_f,
            max_weight: row["max_weight"]&.to_f,
          )
        end
      end

      def rollup_from_billboards(billboards, campaign:, now: Time.current)
        return EMPTY_ROLLUP if billboards.empty?

        campaign_expired = campaign.expired?(now: now)
        live_count = 0
        prioritized_count = 0
        impressions = 0
        clicks = 0
        seconds = 0
        weights = []

        billboards.each do |bb|
          is_live = bb.approved? && bb.published? && !bb.expired?(now: now) && !campaign_expired
          live_count += 1 if is_live
          prioritized_count += 1 if bb.priority?
          impressions += bb.impressions_count.to_i
          clicks += bb.clicks_count.to_i
          seconds += bb.seconds_visible.to_i
          weights << bb.weight.to_f
        end

        CampaignRollup.new(
          billboards_count: billboards.size,
          live_billboards_count: live_count,
          prioritized_count: prioritized_count,
          impressions_count: impressions,
          clicks_count: clicks,
          seconds_visible: seconds,
          min_weight: weights.min,
          max_weight: weights.max,
        )
      end

      def campaign_daily_series(billboard_ids, days: DEFAULT_SERIES_DAYS, now: Time.current)
        ids = Array(billboard_ids).uniq.map(&:to_i).select(&:positive?)
        end_date = now.utc.to_date
        start_date = end_date - (days - 1)
        empty_points = (start_date..end_date).map do |date|
          DailyPoint.new(date: date, impressions: 0, clicks: 0, conversions: 0)
        end

        if ids.empty?
          return DailySeriesResult.new(
            points: empty_points,
            past_24h_impressions: 0,
            past_24h_clicks: 0,
            timed_out: false,
          )
        end

        start_ts = start_date.beginning_of_day.utc
        last_24h_ts = (now - 24.hours).utc
        by_date, past_24h_impressions, past_24h_clicks = query_daily_events(ids, start_ts, last_24h_ts)

        points = (start_date..end_date).map do |date|
          by_date[date] || DailyPoint.new(date: date, impressions: 0, clicks: 0, conversions: 0)
        end

        DailySeriesResult.new(
          points: points,
          past_24h_impressions: past_24h_impressions,
          past_24h_clicks: past_24h_clicks,
          timed_out: false,
        )
      rescue ActiveRecord::QueryCanceled => e
        Rails.logger.warn("Billboards::AdminAnalytics.campaign_daily_series timed out: #{e.message}")
        DailySeriesResult.new(
          points: empty_points,
          past_24h_impressions: 0,
          past_24h_clicks: 0,
          timed_out: true,
        )
      end

      def placement_breakdown(billboards, campaign_expired: false, now: Time.current)
        return [] if billboards.empty?

        total_impressions = billboards.sum { |bb| bb.impressions_count.to_i }
        rows = billboards.group_by(&:placement_area).map do |area, group|
          build_placement_breakdown_row(area, group, total_impressions, campaign_expired: campaign_expired, now: now)
        end
        rows.sort_by { |row| [-row.impressions_count, -row.live_count, row.placement_area] }
      end

      private

      def query_daily_events(ids, start_ts, last_24h_ts)
        by_date = {}
        past_24h_impressions = 0
        past_24h_clicks = 0

        ReadOnlyDatabaseService.with_connection do |conn|
          rows = execute_daily_events_query(conn, ids, start_ts, last_24h_ts)
          rows.each do |row|
            day = Date.parse(row["day"].to_s)
            by_date[day] = DailyPoint.new(
              date: day,
              impressions: row["impressions"].to_i,
              clicks: row["clicks"].to_i,
              conversions: row["conversions"].to_i,
            )
            past_24h_impressions += row["imp_24h"].to_i
            past_24h_clicks += row["clicks_24h"].to_i
          end
        end

        [by_date, past_24h_impressions, past_24h_clicks]
      end

      def execute_daily_events_query(conn, ids, start_ts, last_24h_ts)
        conn.transaction do
          conn.execute("SET LOCAL statement_timeout TO #{STATEMENT_TIMEOUT}")
          conn.execute(daily_events_sql(conn, ids, start_ts, last_24h_ts)).to_a
        end
      end

      def daily_events_sql(conn, ids, start_ts, last_24h_ts)
        q_start = conn.quote(start_ts)
        q_24h = conn.quote(last_24h_ts)
        q_imp = conn.quote(BillboardEvent::CATEGORY_IMPRESSION)
        q_click = conn.quote(BillboardEvent::CATEGORY_CLICK)
        q_signup = conn.quote(BillboardEvent::CATEGORY_SIGNUP)
        q_conv = conn.quote(BillboardEvent::CATEGORY_CONVERSION)

        <<~SQL.squish
          SELECT
            DATE(created_at AT TIME ZONE 'UTC') AS day,
            COALESCE(SUM(counts_for) FILTER (WHERE category = #{q_imp}), 0)::bigint AS impressions,
            COALESCE(SUM(counts_for) FILTER (WHERE category = #{q_click}), 0)::bigint AS clicks,
            COALESCE(SUM(counts_for) FILTER (WHERE category IN (#{q_signup}, #{q_conv})), 0)::bigint AS conversions,
            COALESCE(SUM(counts_for) FILTER (WHERE category = #{q_imp} AND created_at >= #{q_24h}), 0)::bigint AS imp_24h,
            COALESCE(SUM(counts_for) FILTER (WHERE category = #{q_click} AND created_at >= #{q_24h}), 0)::bigint AS clicks_24h
          FROM display_ad_events
          WHERE display_ad_id IN (#{ids.join(', ')})
            AND created_at >= #{q_start}
          GROUP BY day
          ORDER BY day ASC
        SQL
      end

      def build_placement_breakdown_row(area, group, total_impressions, campaign_expired:, now:)
        impressions = group.sum { |bb| bb.impressions_count.to_i }
        clicks = group.sum { |bb| bb.clicks_count.to_i }
        live = group.count { |bb| billboard_live_at?(bb, campaign_expired: campaign_expired, now: now) }
        share = total_impressions.positive? ? (impressions.to_f / total_impressions) : 0.0

        PlacementBreakdownRow.new(
          placement_area: area,
          label: Billboard.human_readable_placement_area(area) || area,
          billboards_count: group.size,
          live_count: live,
          impressions_count: impressions,
          clicks_count: clicks,
          impression_share: share,
        )
      end

      def billboard_live_at?(billboard, campaign_expired:, now:)
        billboard.approved? && billboard.published? && !billboard.expired?(now: now) && !campaign_expired
      end
    end
  end
end
