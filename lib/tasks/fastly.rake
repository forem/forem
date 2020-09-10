namespace :fastly do
  desc "Update Fastly configs"
  task update_configs: :environment do
    unless ENV["SKIP_FASTLY_CONFIG_UPDATE"] == "true"
      fastly_credentials = %w[
        FASTLY_API_KEY
        FASTLY_SERVICE_ID
      ]

      if fastly_credentials.any? { |cred| ApplicationConfig[cred].blank? }
        Rails.logger.info(
          "Fastly not configured. Please set #{fastly_credentials.join(', ')} in your environment.",
        )

        next
      end

      FastlyConfig::Update.call
    end
  end
end
