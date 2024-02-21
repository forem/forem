class PageViewRollupWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority

  def perform
    five_month_ago = Date.current - 5.months
    PageViewRollup.rollup five_month_ago
  end
end
