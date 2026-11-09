module Organizations
  class DeleteCustomDomainWorker
    include Sidekiq::Job
    sidekiq_options queue: :default, retry: 5, lock: :until_executing, on_conflict: :replace

    def perform(tls_subscription_id)
      return if tls_subscription_id.blank?

      client = tls_client
      return unless client

      begin
        client.delete_subscription(tls_subscription_id)
      rescue StandardError => e
        Rails.logger.error(
          "Failed to delete TLS subscription #{tls_subscription_id} in background worker: #{e.class} #{e.message}"
        )
        raise
      end
    end

    private

    def tls_client
      return FastlyTls::Client if ApplicationConfig["FASTLY_API_KEY"].present?
      return CloudflareTls::Client if CloudflareTls::Client.configured?

      nil
    end
  end
end
