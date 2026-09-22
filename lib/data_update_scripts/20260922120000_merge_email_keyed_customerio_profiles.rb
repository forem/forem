module DataUpdateScripts
  # Before Deliverable keyed unlinked recipients as "dev:<id>", mail sent to a
  # new user before their mlh identity landed was keyed by email. Customer.io
  # stored that address as the person's id, leaving an orphan profile beside
  # the one keyed by the MLH uid that nothing ever merges. Merge each orphan
  # into its linked person.
  #
  # Scoped to users linked after signup since Customer.io delivery shipped
  # (2026-07-16) -- the only accounts that could have been mailed unlinked.
  # Users never mailed before linking have no orphan; their merges come back as
  # per-op errors in a 207, which the client treats as success, so they never
  # fail the batch.
  class MergeEmailKeyedCustomerioProfiles
    ROLLOUT_DATE = Time.zone.parse("2026-07-16")
    # /v2/batch caps a request at 500KB; a merge op is ~150 bytes.
    BATCH_SIZE = 1_000

    def run
      return unless ForemInstance.customerio_track_enabled?

      User.where(created_at: ROLLOUT_DATE..).where.not(email: [nil, ""]).in_batches(of: BATCH_SIZE) do |users|
        ops = users.joins(:identities)
          .where(identities: { provider: "mlh" })
          .where("identities.created_at > users.created_at")
          .pluck("identities.uid", "users.email")
          .map { |uid, email| { type: "person", action: "merge", primary: { id: uid }, secondary: { id: email } } }
        CUSTOMERIO_TRACK_API.batch(ops) if ops.any?
      end
    end
  end
end
