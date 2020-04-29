namespace :fastly do
  desc "Update VCL for safe params on Fastly"
  task update_safe_params: :environment do
    fastly_credentials = %w[
      FASTLY_API_KEY
      FASTLY_SERVICE_ID
      FASTLY_SAFE_PARAMS_SNIPPET_NAME
    ]

    if fastly_credentials.any? { |cred| ApplicationConfig[cred].blank? }
      Rails.logger.info(
        "Fastly not configured. Please set #{fastly_credentials.join(", ")} in your environment."
      )

      next
    end

    FastlyVCL::SafeParams.update
  end
end
