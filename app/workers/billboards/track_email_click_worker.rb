module Billboards
  class TrackEmailClickWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    TALLY_COLUMNS = [
      "COALESCE(SUM(counts_for) FILTER (WHERE category = '#{BillboardEvent::CATEGORY_IMPRESSION}'), 0)",
      "COALESCE(SUM(counts_for) FILTER (WHERE category = '#{BillboardEvent::CATEGORY_CLICK}'), 0)",
      "COALESCE(SUM(seconds_visible) FILTER (WHERE category = '#{BillboardEvent::CATEGORY_IMPRESSION}'), 0)",
    ].map { |sql| Arel.sql(sql) }.freeze

    def perform(bb_param, user_id)
      @bb = bb_param
      @user = User.find_by(id: user_id)
      track_billboard
    end

    private

    def track_billboard
      ApplicationRecord.with_synchronous_commit_off do
        BillboardEvent.create(billboard_id: @bb.to_i,
                              category: "click",
                              user_id: @user&.id,
                              context_type: "email")
        update_billboard_counts
      end
    rescue StandardError => e
      Rails.logger.error "Error processing billboard click: #{e.message}"
    end

    def update_billboard_counts
      billboard = Billboard.find_by(id: @bb.to_i)
      return unless billboard

      # One pass over the billboard's events instead of one SUM query per tally.
      num_impressions, num_clicks, num_seconds_visible = billboard.billboard_events.pick(*TALLY_COLUMNS)
      rate = num_impressions.positive? ? (num_clicks.to_f / num_impressions) : 0
      billboard.update_columns(
        success_rate: rate,
        clicks_count: num_clicks,
        impressions_count: num_impressions,
        seconds_visible: num_seconds_visible,
      )
    end
  end
end
