class IdentifyTrendsWorker
  include Sidekiq::Job
  sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

  def perform
    return unless Ai::Base::DEFAULT_KEY.present?

    Ai::TrendDetector.new.call
  end
end
