module Organizations
  class ReverifyAllWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 1

    def perform
      Organization.where(verified: true).where.not(verification_url: [nil, ""])
        .find_each do |organization|
        result = Organizations::VerifyLinkback.call(organization)
        next if result.success?

        organization.update_columns(verified: false, verified_at: nil)
      end
    end
  end
end
