module DataUpdateScripts
  # Before Deliverable held mail for users without an mlh identity, mail sent
  # to a new user before that link landed was keyed by email. Customer.io
  # stored that address as the person's id, leaving an orphan profile beside
  # the one keyed by the MLH uid that nothing ever merges. Merge each orphan
  # into its linked person.
  #
  # Scoped to users created since Customer.io delivery shipped (2026-07-16) --
  # the only accounts that could have been mailed unlinked. The merges run as
  # one worker per id range, staggered so ~107k Track API calls stay well under
  # the rate limit and a deploy restart only interrupts a single range.
  class MergeEmailKeyedCustomerioProfiles
    ROLLOUT_DATE = Time.zone.parse("2026-07-16")
    RANGE_SIZE = 1_000
    STAGGER = 1.minute

    def run
      return unless ForemInstance.customerio_track_enabled?

      # Not minimum(:id) -- Postgres plans that as a filtered primary key walk
      # over every older user; ordering by created_at reads its index instead.
      start_id = User.where(created_at: ROLLOUT_DATE..).order(:created_at).pick(:id)
      return unless start_id

      (start_id..User.maximum(:id)).step(RANGE_SIZE).each_with_index do |range_start, i|
        Emails::MergeEmailKeyedCustomerioProfilesWorker
          .perform_in(i * STAGGER, range_start, range_start + RANGE_SIZE - 1)
      end
    end
  end
end
