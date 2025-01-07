module Billboards
  class TrackEmailClickWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform(bb_param, user_id)
      @bb = bb_param
      @user = User.find_by(id: user_id)
      track_billboard
    end

    private

    def track_billboard
      BillboardEvent.create(billboard_id: @bb.to_i,
                            category: "click",
                            user_id: @user&.id,
                            context_type: "email")
      update_billboard_counts
    rescue StandardError => e
      Rails.logger.error "Error processing billboard click: #{e.message}"
    end

    def update_billboard_counts
      billboard = Billboard.find_by(id: @bb.to_i)
      return unless billboard

      num_impressions = billboard.billboard_events.impressions.sum(:counts_for)
      num_clicks = billboard.billboard_events.clicks.sum(:counts_for)
      rate = num_impressions.positive? ? (num_clicks.to_f / num_impressions) : 0
      billboard.update_columns(
        success_rate: rate,
        clicks_count: num_clicks,
        impressions_count: num_impressions,
      )
    end
  end
end
