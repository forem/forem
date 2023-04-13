class AudienceSegmentRefreshWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority

  def perform(*ids)
    if ids.blank?
      ids = DisplayAd.distinct(:audience_segment_id).pluck(:audience_segment_id).compact
    end
    AudienceSegment.where(id: ids).find_each(&:refresh!)
  end
end
