module SegmentedUsers
  # Preferred way to add a large number of users to an AudienceSegment
  # Normal ActiveRecord usage emits one INSERT statement per row.
  class BulkUpsert
    Result = Struct.new(:succeeded, :failed, keyword_init: true)

    def self.call(audience_segment, user_ids:)
      new(audience_segment).call(user_ids)
    end

    # @param audience_segment [AudienceSegment] the segment to add users to
    def initialize(audience_segment)
      @audience_segment = audience_segment
    end

    # Upserts the provided users into the AudienceSegment in batches.
    # It touches the `SegmentedUser` record of any users already in the list, as
    # well as the segment itself if any users were successfully upserted.
    #
    # Warning: the joining `SegmentedUsers` records are created without triggering any
    # application-defined callbacks. Doing so is the responsibility of the caller.
    #
    # @param user_ids [Array<Integer>] a list of `User` ids to process
    # @return [SegmentedUsers::BulkUpsert::Result]
    def call(user_ids)
      return unless audience_segment.persisted?

      @upsert_time = Time.current

      valid_user_ids = User.where(id: user_ids).ids
      upserted_user_ids = upsert_in_batches(valid_user_ids)

      audience_segment.touch unless upserted_user_ids.empty?

      Result.new(succeeded: upserted_user_ids, failed: user_ids - upserted_user_ids)
    end

    private

    attr_reader :audience_segment, :upsert_time

    def upsert_in_batches(user_ids)
      result = []

      user_ids.in_groups_of(1000, false) do |ids|
        succeeded = perform_upsert(ids).rows.flatten
        result.concat(succeeded)
      end

      result
    end

    def perform_upsert(user_ids_batch)
      segmented_users = build_records(user_ids_batch)

      # We only want to touch the `updated_at` column of records that already exist,
      # but specifying that causes ActiveRecord to emit malformed SQL (multiple assignments to the same column).
      # Turning off Rails' automatic timestamp management via `record_timestamps`
      # and managing timestamps ourselves yields the correct query.
      SegmentedUser.upsert_all(
        segmented_users,
        unique_by: :index_segmented_users_on_audience_segment_and_user,
        update_only: [:updated_at],
        returning: ["user_id"],
        record_timestamps: false,
      )
    end

    def build_records(user_ids_batch)
      user_ids_batch.map do |user_id|
        {
          audience_segment_id: audience_segment.id,
          user_id: user_id,
          created_at: upsert_time,
          updated_at: upsert_time
        }
      end
    end
  end
end
