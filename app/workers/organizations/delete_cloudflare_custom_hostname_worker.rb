module Organizations
  class DeleteCloudflareCustomHostnameWorker
    include Sidekiq::Job
    sidekiq_options queue: :default, retry: 5, lock: :until_executing, on_conflict: :replace

    def perform(custom_hostname_id)
      return if custom_hostname_id.blank?
      return unless CloudflareSaas.enabled?

      CloudflareSaas::Client.delete_custom_hostname(custom_hostname_id)
    rescue CloudflareSaas::Client::Error => e
      Rails.logger.error(
        "Failed to delete Cloudflare custom hostname #{custom_hostname_id}: #{e.class} #{e.message}",
      )
      raise
    end
  end
end
