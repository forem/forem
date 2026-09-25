module Organizations
  class ProvisionCustomDomainWorker
    include Sidekiq::Job

    # If events coalesce, we only need to provision once
    sidekiq_options lock: :until_executing, on_conflict: :replace

    def perform(organization_id)
      organization = Organization.find_by(id: organization_id)
      return unless organization
      return if organization.custom_domain.blank?

      if CloudflareSaas.enabled?
        provision_cloudflare(organization)
      elsif ApplicationConfig["FASTLY_API_KEY"].present?
        provision_fastly(organization)
      end
    end

    private

    def provision_cloudflare(organization)
      return if organization.cloudflare_custom_hostname_id.present?

      domain = organization.custom_domain
      record = CloudflareSaas::Client.create_custom_hostname(domain)

      # The domain may have been changed or removed while the API call was in flight.
      if organization.reload.custom_domain != domain
        CloudflareSaas::Client.delete_custom_hostname(record["id"]) unless Organization.exists?(custom_domain: domain)
        return
      end

      organization.update_columns(
        cloudflare_custom_hostname_id: record["id"],
        tls_status: Organization.tls_statuses[:pending],
        custom_domain_error: nil,
      )
      Organizations::VerifyCustomDomainWorker.perform_in(1.minute, organization.id)
    rescue CloudflareSaas::Client::Error => e
      # Cloudflare rejected the hostname itself (e.g. it is not allowed). Retrying
      # will not help, so surface the reason to the organization instead.
      raise unless e.client_error?

      organization.update_columns(
        tls_status: Organization.tls_statuses[:failed],
        custom_domain_error: e.message.delete_prefix("Cloudflare API Error: ").truncate(255),
      )
    end

    def provision_fastly(organization)
      # If there's already a subscription ID, we assume it's valid for this domain.
      # Changes to custom_domain clear tls_subscription_id in the model.
      return if organization.tls_subscription_id.present?

      subscription_id = FastlyTls::Client.create_subscription(organization.custom_domain)

      organization.update_columns(
        tls_subscription_id: subscription_id,
        tls_status: Organization.tls_statuses[:pending],
      )

      # Start verification polling
      Organizations::VerifyCustomDomainWorker.perform_in(30.seconds, organization.id)
    end
  end
end
