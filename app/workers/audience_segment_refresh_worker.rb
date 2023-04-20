class AudienceSegmentRefreshWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority

  def perform(*ids)
    ids = ids.flatten
    AudienceSegment.where(id: ids).find_each(&:refresh!)
  end
end
