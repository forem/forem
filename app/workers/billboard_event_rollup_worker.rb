class DisplayAdEventRollupWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority

  def perform
    month_ago = Date.current - 32.days
    DisplayAdEventRollup.rollup month_ago
  end
end
