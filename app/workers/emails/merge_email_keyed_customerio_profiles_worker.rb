module Emails
  # Merges the email-keyed Customer.io person minted for a user mailed before
  # their mlh identity landed into their Core-keyed person, for the users in
  # [start_id, end_id]. Enqueued by the MergeEmailKeyedCustomerioProfiles data
  # update script.
  #
  # One v1 merge per user: /api/v2/batch accepts "merge" ops with a 200 and
  # never applies them. A merge whose secondary does not exist is also a 200,
  # so users without an orphan are harmless no-ops, and merges are idempotent,
  # so a retry after a 429 just redoes the range.
  class MergeEmailKeyedCustomerioProfilesWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform(start_id, end_id)
      User.where(id: start_id..end_id)
        .where.not(email: [nil, ""])
        .joins(:identities)
        .where(identities: { provider: "mlh" })
        .where("identities.created_at > users.created_at")
        .pluck("identities.uid", "users.email")
        .each { |uid, email| CUSTOMERIO_TRACK_API.merge_customers("id", uid, "id", email) }
    end
  end
end
