module Organizations
  class ProvisionCustomDomainWorker
    include Sidekiq::Job

    # If events coalesce, we only need to provision once
    sidekiq_options lock: :until_executing, on_conflict: :replace

    def perform(organization_id)
      return if ApplicationConfig["FASTLY_API_KEY"].blank?

      organization = Organization.find_by(id: organization_id)
      return unless organization
      return if organization.custom_domain.blank?

      # If there's already a subscription ID, we assume it's valid for this domain.
      # Changes to custom_domain should clear tls_subscription_id in the model.
      return if organization.tls_subscription_id.present?

      subscription_id = FastlyTls::Client.create_subscription(organization.custom_domain)
      
      organization.update_columns(
        tls_subscription_id: subscription_id,
        tls_status: Organization.tls_statuses[:pending]
      )

      # Start verification polling
      Organizations::VerifyCustomDomainWorker.perform_in(30.seconds, organization.id)
    end
  end
end
