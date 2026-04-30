module Organizations
  class DeleteCustomDomainWorker
    include Sidekiq::Job
    sidekiq_options queue: :default, retry: 5, lock: :until_executing, on_conflict: :replace

    def perform(tls_subscription_id)
      return if tls_subscription_id.blank?
      return unless ApplicationConfig["FASTLY_API_KEY"].present?

      begin
        FastlyTls::Client.delete_subscription(tls_subscription_id)
      rescue StandardError => e
        Rails.logger.error(
          "Failed to delete Fastly TLS subscription #{tls_subscription_id} in background worker: #{e.class} #{e.message}"
        )
        raise
      end
    end
  end
end
