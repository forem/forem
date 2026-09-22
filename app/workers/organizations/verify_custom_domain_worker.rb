module Organizations
  class VerifyCustomDomainWorker
    include Sidekiq::Job

    # Lock to prevent concurrent verification
    sidekiq_options lock: :until_executing, on_conflict: :replace

    # Cloudflare custom hostname states, see
    # https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/reference/status-codes/
    CLOUDFLARE_LIVE_SSL_STATUSES = %w[active pending_expiration backup_issued].freeze
    CLOUDFLARE_FAILED_HOSTNAME_STATUSES = %w[blocked pending_blocked moved deleted pending_deletion].freeze
    CLOUDFLARE_FAILED_SSL_STATUSES = %w[
      expired deleted initializing_timed_out validation_timed_out issuance_timed_out deployment_timed_out
    ].freeze

    # Check often right after the domain is added, while the organization is
    # likely setting up DNS, then back off. Give up after a week.
    CLOUDFLARE_FAST_CHECK_WINDOW = 1.hour
    CLOUDFLARE_FAST_CHECK_INTERVAL = 5.minutes
    CLOUDFLARE_SLOW_CHECK_INTERVAL = 1.hour
    CLOUDFLARE_MAX_PENDING_AGE = 7.days

    def perform(organization_id)
      organization = Organization.find_by(id: organization_id)
      return unless organization

      if organization.cloudflare_custom_hostname_id.present?
        verify_cloudflare(organization) if CloudflareSaas.enabled?
      elsif organization.tls_subscription_id.present?
        verify_fastly(organization) if ApplicationConfig["FASTLY_API_KEY"].present?
      end
    end

    private

    def verify_cloudflare(organization)
      record = CloudflareSaas::Client.get_custom_hostname(organization.cloudflare_custom_hostname_id)
      was_live = organization.custom_domain_live?

      if record.nil?
        # The hostname was deleted on Cloudflare, so clear the stale reference
        organization.update_columns(
          tls_status: Organization.tls_statuses[:failed],
          cloudflare_custom_hostname_id: nil,
          custom_domain_error: nil,
        )
      elsif cloudflare_live?(record)
        organization.update_columns(tls_status: Organization.tls_statuses[:issued], custom_domain_error: nil)
      elsif cloudflare_failed?(record)
        organization.update_columns(
          tls_status: Organization.tls_statuses[:failed],
          custom_domain_error: cloudflare_error_message(record),
        )
      else
        next_check = next_cloudflare_check_in(record)
        organization.update_columns(
          tls_status: Organization.tls_statuses[next_check ? :pending : :failed],
          custom_domain_error: cloudflare_error_message(record),
        )
        Organizations::VerifyCustomDomainWorker.perform_in(next_check, organization.id) if next_check
      end

      # Links and redirects switch between the main domain and the custom domain
      # when it goes live or stops being live, so purge the organization's pages.
      return if organization.custom_domain_live? == was_live

      Organizations::BustCacheWorker.perform_async(organization.id, organization.slug)
    end

    def cloudflare_live?(record)
      record["status"] == "active" && CLOUDFLARE_LIVE_SSL_STATUSES.include?(record.dig("ssl", "status"))
    end

    def cloudflare_failed?(record)
      CLOUDFLARE_FAILED_HOSTNAME_STATUSES.include?(record["status"]) ||
        CLOUDFLARE_FAILED_SSL_STATUSES.include?(record.dig("ssl", "status"))
    end

    def cloudflare_error_message(record)
      messages = Array(record["verification_errors"]).map(&:to_s)
      messages += Array(record.dig("ssl", "validation_errors")).map do |error|
        error.is_a?(Hash) ? error["message"] : error
      end
      messages.compact_blank.uniq.join(" ").truncate(255).presence
    end

    def next_cloudflare_check_in(record)
      created_at = Time.zone.parse(record["created_at"].to_s) || Time.current
      age = Time.current - created_at
      return if age > CLOUDFLARE_MAX_PENDING_AGE

      age < CLOUDFLARE_FAST_CHECK_WINDOW ? CLOUDFLARE_FAST_CHECK_INTERVAL : CLOUDFLARE_SLOW_CHECK_INTERVAL
    rescue ArgumentError
      CLOUDFLARE_SLOW_CHECK_INTERVAL
    end

    def verify_fastly(organization)
      subscription_data = FastlyTls::Client.get_subscription(organization.tls_subscription_id)

      if subscription_data.nil?
        # Subscription was deleted on Fastly, so clear the stale upstream reference
        organization.update_columns(
          tls_status: Organization.tls_statuses[:failed],
          tls_subscription_id: nil,
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
