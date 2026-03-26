module Organizations
  class ReverifyOneWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 3

    def perform(organization_id)
      organization = Organization.find_by(id: organization_id)
      return unless organization&.verified?

      result = Organizations::VerifyLinkback.call(organization)
      return if result.success?

      organization.update_columns(verified: false, verified_at: nil)
      Notifications::OrganizationDeverificationWorker.perform_async(organization.id)
    end
  end
end
