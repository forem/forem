module Billboards
  # Runs every 5 minutes to take down approved billboards and campaigns whose expiration date
  # or delivery caps (impressions/clicks) have been reached, even without incoming traffic events.
  class EnforceDeliveryLimitsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 3, lock: :until_executing, on_conflict: :replace

    def perform
      Billboards::EnforceDeliveryLimits.sweep!
    end
  end
end
