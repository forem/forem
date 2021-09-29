module Discover
  class RegisterWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 3

    def perform
      Discover::Register.call(domain: Settings::General.app_domain)
    end
  end
end
