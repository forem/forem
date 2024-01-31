class AudienceSegmentRefreshAllWorker
  include Sidekiq::Job

  sidekiq_options queue: :low_priority

  def perform
    ids = Billboard.approved_and_published
      .distinct(:audience_segment_id)
      .pluck(:audience_segment_id).compact

    AudienceSegmentRefreshWorker.perform_bulk(ids.zip)
  end
end
