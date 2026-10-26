# app/workers/billboards/data_update_worker.rb
module Billboards
  class DataUpdateWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    CONVERSION_SUCCESS_MODIFIER = 25

    TALLY_COLUMNS = [
      "COALESCE(SUM(counts_for) FILTER (WHERE category = '#{BillboardEvent::CATEGORY_IMPRESSION}'), 0)",
      "COALESCE(SUM(counts_for) FILTER (WHERE category = '#{BillboardEvent::CATEGORY_CLICK}'), 0)",
      "COALESCE(SUM(counts_for) FILTER (WHERE category IN " \
      "('#{BillboardEvent::CATEGORY_SIGNUP}', '#{BillboardEvent::CATEGORY_CONVERSION}')), 0)",
      "COALESCE(SUM(seconds_visible) FILTER (WHERE category = '#{BillboardEvent::CATEGORY_IMPRESSION}'), 0)",
    ].map { |sql| Arel.sql(sql) }.freeze

    def perform(billboard_id)
      perform_update(billboard_id)
    end

    private

    def perform_update(billboard_id)
      billboard = Billboard.find(billboard_id)
      timestamp = Time.current

      # Check and handle expiration before processing other updates
      billboard.check_and_handle_expiration

      return if rand(3) > 0 && billboard.impressions_count > 500_000
      return if rand(2).zero? && billboard.impressions_count > 100_000

      if billboard.counts_tabulated_at.present?
        cutoff = billboard.counts_tabulated_at

        num_impressions, num_clicks, num_conversions, num_seconds_visible =
          tally_events(billboard.billboard_events.where("created_at > ?", cutoff))
        conversion_success = num_conversions * CONVERSION_SUCCESS_MODIFIER

        new_clicks      = billboard.clicks_count + num_clicks
        new_impressions = billboard.impressions_count + num_impressions
        new_seconds_visible = billboard.seconds_visible + num_seconds_visible
        rate = (new_clicks + conversion_success).to_f / new_impressions

        billboard.update_columns(
          success_rate:        rate,
          clicks_count:        new_clicks,
          impressions_count:   new_impressions,
          seconds_visible:     new_seconds_visible,
          counts_tabulated_at: timestamp
        )
      else
        num_impressions, num_clicks, num_conversions, num_seconds_visible = tally_events(billboard.billboard_events)
        conversion_success = num_conversions * CONVERSION_SUCCESS_MODIFIER

        rate = (num_clicks + conversion_success).to_f / num_impressions

        billboard.update_columns(
          success_rate:        rate,
          clicks_count:        num_clicks,
          impressions_count:   num_impressions,
          seconds_visible:     num_seconds_visible,
          counts_tabulated_at: timestamp
        )
      end
    end

    # Sums every category in one pass over the billboard's events instead of
    # one SUM query (and one index walk) per category.
    #
    # @return [Array<Integer>] impressions, clicks, conversions, seconds visible
    def tally_events(events)
      events.pick(*TALLY_COLUMNS)
    end
  end
end
