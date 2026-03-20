module Organizations
  class VerifyLinkbackWorker
    include Sidekiq::Job

    sidekiq_options queue: :default, retry: 3

    def perform(organization_id)
      organization = Organization.find_by(id: organization_id)
      return unless organization

      Organizations::VerifyLinkback.call(organization)
    end
  end
end
