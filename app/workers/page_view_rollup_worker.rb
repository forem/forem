class PageViewRollupWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority, retry: false

  def perform
    one_year_ago = 1.year.ago
    PageViewRollup.rollup one_year_ago
  end
end
