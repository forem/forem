module Notifications
  class NewEndorsementWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(endorsement_id)
      endorsement = ListingEndorsement.find(endorsement_id)

      Notifications::NewEndorsement::Send.call(endorsement)
    end
  end
end
