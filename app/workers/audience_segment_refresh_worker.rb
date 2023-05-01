class AudienceSegmentRefreshWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority

  def perform(id)
    AudienceSegment.find(id).refresh!
  end
end
