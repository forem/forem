module Notifications
  class OrganizationDeverificationWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform(organization_id)
      organization = Organization.find_by(id: organization_id)
      Notifications::OrganizationDeverification::Send.call(organization) if organization
    end
  end
end
