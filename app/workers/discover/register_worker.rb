module Discover
  class RegisterWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 3

    def perform(domain = Settings::General.app_domain)
      Discover::Register.call(domain: domain)
    end
  end
end
