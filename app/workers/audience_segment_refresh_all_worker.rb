class AudienceSegmentRefreshAllWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority

  def perform
    ids = DisplayAd.approved_and_published
      .distinct(:audience_segment_id)
      .pluck(:audience_segment_id).compact

    AudienceSegmentRefreshWorker.perform_bulk([ids])
  end
end
