# app/workers/billboards/data_update_worker.rb
module Billboards
  class DataUpdateWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    CONVERSION_SUCCESS_MODIFIER = 25

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

        num_impressions = billboard.billboard_events
                                 .impressions
                                 .where("created_at > ?", cutoff)
                                 .sum(:counts_for)

        num_clicks      = billboard.billboard_events
                                 .clicks
                                 .where("created_at > ?", cutoff)
                                 .sum(:counts_for)

        conversion_success = billboard.billboard_events
                                     .all_conversion_types
                                     .where("created_at > ?", cutoff)
                                     .sum(:counts_for) * CONVERSION_SUCCESS_MODIFIER

        new_clicks      = billboard.clicks_count + num_clicks
        new_impressions = billboard.impressions_count + num_impressions
        rate = (new_clicks + conversion_success).to_f / new_impressions

        billboard.update_columns(
          success_rate:        rate,
          clicks_count:        new_clicks,
          impressions_count:   new_impressions,
          counts_tabulated_at: timestamp
        )
      else
        num_impressions    = billboard.billboard_events.impressions.sum(:counts_for)
        num_clicks         = billboard.billboard_events.clicks.sum(:counts_for)
        conversion_success = billboard.billboard_events.all_conversion_types.sum(:counts_for) * CONVERSION_SUCCESS_MODIFIER

        rate = (num_clicks + conversion_success).to_f / num_impressions

        billboard.update_columns(
          success_rate:        rate,
          clicks_count:        num_clicks,
          impressions_count:   num_impressions,
          counts_tabulated_at: timestamp
        )
      end
    end
  end
end
