namespace :cloudflare do
  desc "Update Cloudflare edge worker config"
  task update_configs: :environment do
    unless ENV["SKIP_CLOUDFLARE_CONFIG_UPDATE"] == "true"
      cloudflare_credentials = %w[
        CLOUDFLARE_API_TOKEN
        CLOUDFLARE_ACCOUNT_ID
      ]

      if cloudflare_credentials.any? { |cred| ApplicationConfig[cred].blank? }
        Rails.logger.info(
          "Cloudflare not configured. Please set #{cloudflare_credentials.join(', ')} in your environment.",
        )

        next
      end

      CloudflareConfig::Update.call
    end
  end
end
