module Organizations
  class VerifyCustomDomainWorker
    include Sidekiq::Job

    # Lock to prevent concurrent verification
    sidekiq_options lock: :until_executing, on_conflict: :replace

    def perform(organization_id)
      return if ApplicationConfig["FASTLY_API_KEY"].blank?

      organization = Organization.find_by(id: organization_id)
      return unless organization
      return if organization.tls_subscription_id.blank?

      subscription_data = FastlyTls::Client.get_subscription(organization.tls_subscription_id)
      
      if subscription_data.nil?
        # Subscription was deleted on Fastly, so clear the stale upstream reference
        organization.update_columns(
          tls_status: Organization.tls_statuses[:failed],
          tls_subscription_id: nil
        )
        return
      end

      state = subscription_data.dig("attributes", "state")

      case state
      when "issued", "renewing"
        organization.update_columns(tls_status: Organization.tls_statuses[:issued])
      when "pending", "processing"
        # Re-enqueue in 1 hour if it's still waiting on the user's DNS or Fastly challenge
        Organizations::VerifyCustomDomainWorker.perform_in(1.hour, organization.id)
      else
        # If it failed or was destroyed upstream, mark it as failed
        organization.update_columns(tls_status: Organization.tls_statuses[:failed])
      end
    end
  end
end
