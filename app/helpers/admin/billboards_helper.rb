module Admin
  module BillboardsHelper
    BILLBOARD_FILTER_KEYS = %i[
      search status billboard_campaign_id placement_area type_of
      display_to priority render_mode organization_id tag sort
    ].freeze

    CAMPAIGN_FILTER_KEYS = %i[search status sort].freeze

    def admin_bb_compact_number(value)
      num = value.to_i
      return "0" if num.zero?
      return format("%.1fM", num / 1_000_000.0).sub(/\.0M\z/, "M") if num.abs >= 1_000_000
      return format("%.1fK", num / 1_000.0).sub(/\.0K\z/, "K") if num.abs >= 10_000

      number_with_delimiter(num)
    end

    def admin_bb_ctr_percentage(clicks, impressions)
      imp = impressions.to_i
      return "—" unless imp.positive?

      format("%.2f%%", (clicks.to_f / imp) * 100.0)
    end

    def admin_bb_avg_seconds(seconds, impressions)
      imp = impressions.to_i
      return "—" unless imp.positive?

      format("%.1fs", seconds.to_f / imp)
    end

    def admin_bb_status(billboard, now: Time.current)
      campaign = billboard.billboard_campaign

      if billboard.expired?(now: now) || campaign&.expired?(now: now)
        { key: :expired, label: t("views.admin.billboards.status.expired"), tone: "danger" }
      elsif billboard.over_cap?
        { key: :capped, label: t("views.admin.billboards.status.capped"), tone: "warning" }
      elsif billboard.approved? && billboard.published?
        { key: :live, label: t("views.admin.billboards.status.live"), tone: "success" }
      elsif billboard.published? && !billboard.approved?
        { key: :awaiting_approval, label: t("views.admin.billboards.status.unapproved"), tone: "neutral" }
      else
        { key: :draft, label: t("views.admin.billboards.status.draft"), tone: "neutral" }
      end
    end

    def admin_campaign_status(campaign, rollup:, now: Time.current)
      if campaign.expired?(now: now)
        { key: :expired, label: t("views.admin.billboard_campaigns.status.expired"), tone: "danger" }
      elsif campaign_over_cap_from_rollup?(campaign, rollup)
        { key: :capped, label: t("views.admin.billboard_campaigns.status.capped"), tone: "warning" }
      elsif rollup.live_billboards_count.positive? && campaign.ideal_daily_impressions.to_i.positive? &&
          campaign.delivery_throttle_rate.to_f < 1.0
        { key: :throttled, label: t("views.admin.billboard_campaigns.status.throttled"), tone: "info" }
      elsif rollup.live_billboards_count.positive?
        { key: :active, label: t("views.admin.billboard_campaigns.status.active"), tone: "success" }
      else
        { key: :idle, label: t("views.admin.billboard_campaigns.status.idle"), tone: "neutral" }
      end
    end

    def campaign_over_cap_from_rollup?(campaign, rollup)
      (campaign.max_impressions_count.to_i.positive? &&
        rollup.impressions_count >= campaign.max_impressions_count.to_i) ||
        (campaign.max_clicks_count.to_i.positive? &&
          rollup.clicks_count >= campaign.max_clicks_count.to_i)
    end

    def admin_bb_cap_progress(current, cap)
      cap_i = cap.to_i
      return unless cap_i.positive?

      curr_i = current.to_i
      pct = ((curr_i.to_f / cap_i) * 100.0).clamp(0.0, 100.0)
      tone = if curr_i >= cap_i
               "danger"
             elsif pct >= 85.0
               "warning"
             else
               "brand"
             end

      {
        current: curr_i,
        cap: cap_i,
        percent: pct,
        remaining: [cap_i - curr_i, 0].max,
        tone: tone,
        reached: curr_i >= cap_i
      }
    end

    def admin_bb_schedule_summary(expires_at, created_at: nil, now: Time.current)
      return if expires_at.blank?

      diff = expires_at - now
      if diff <= 0
        {
          label: t("views.admin.billboards.schedule.expired_ago", time: distance_of_time_in_words(expires_at, now)),
          tone: "danger",
          elapsed_percent: 100.0
        }
      else
        tone = diff <= Billboards::AdminAnalytics::EXPIRING_SOON_WINDOW ? "warning" : "neutral"
        elapsed = if created_at.present? && expires_at > created_at
                    (((now - created_at) / (expires_at - created_at)) * 100.0).clamp(0.0, 100.0)
                  end

        {
          label: t("views.admin.billboards.schedule.ends_in", time: distance_of_time_in_words(now, expires_at)),
          tone: tone,
          elapsed_percent: elapsed
        }
      end
    end

    def admin_billboard_filter_params(overrides = {})
      base = params.permit(*BILLBOARD_FILTER_KEYS).to_h.symbolize_keys.compact_blank
      base.merge(overrides).compact_blank
    end

    def admin_campaign_filter_params(overrides = {})
      base = params.permit(*CAMPAIGN_FILTER_KEYS).to_h.symbolize_keys.compact_blank
      base.merge(overrides).compact_blank
    end

    def admin_billboard_active_filter_chips(campaigns_by_id = {})
      BILLBOARD_FILTER_KEYS.excluding(:sort).filter_map do |key|
        value = params[key]
        next if value.blank?

        { key: key, label: admin_bb_filter_chip_label(key, value.to_s, campaigns_by_id) }
      end
    end

    def admin_billboard_live_preview_path(billboard)
      "/?bb_test_placement_area=#{ERB::Util.url_encode(billboard.placement_area)}&bb_test_id=#{billboard.id}"
    end

    private

    def admin_bb_filter_chip_label(key, value, campaigns_by_id)
      case key
      when :search then "#{t('views.admin.billboards.filters.search')}: \"#{value}\""
      when :status then "#{t('views.admin.billboards.filters.status')}: #{value.humanize}"
      when :billboard_campaign_id
        "#{t('views.admin.billboards.filters.campaign')}: #{admin_bb_campaign_chip_value(value, campaigns_by_id)}"
      when :placement_area
        area = Billboard.human_readable_placement_area(value) || value
        "#{t('views.admin.billboards.filters.placement')}: #{area}"
      when :priority
        label = value == "true" ? "prioritized_only" : "non_prioritized"
        "#{t('views.admin.billboards.filters.priority')}: #{t("views.admin.billboards.filters.#{label}")}"
      else
        admin_bb_simple_chip_label(key, value)
      end
    end

    def admin_bb_campaign_chip_value(value, campaigns_by_id)
      return t("views.admin.billboards.filters.standalone") if value == "none"

      campaign = campaigns_by_id[value.to_i]
      campaign ? "#{campaign.name} (##{campaign.id})" : "##{value}"
    end

    def admin_bb_simple_chip_label(key, value)
      case key
      when :type_of
        label = t("views.admin.billboards.filters.types.#{value}", default: value.humanize)
        "#{t('views.admin.billboards.filters.type')}: #{label}"
      when :display_to
        label = t("views.admin.billboards.filters.audiences.#{value}", default: value.humanize)
        "#{t('views.admin.billboards.filters.audience')}: #{label}"
      when :render_mode
        label = t("views.admin.billboards.filters.render_modes.#{value}", default: value.humanize)
        "#{t('views.admin.billboards.filters.render_mode')}: #{label}"
      when :tag then "#{t('views.admin.billboards.filters.tag')}: ##{value}"
      when :organization_id then "#{t('views.admin.billboards.filters.org_id')}: ##{value}"
      else value
      end
    end
  end
end
