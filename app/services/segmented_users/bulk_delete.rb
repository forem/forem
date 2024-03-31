module SegmentedUsers
  # Preferred way to quickly remove a large number of users from an AudienceSegment
  class BulkDelete
    Result = Struct.new(:succeeded, :failed, keyword_init: true)

    def self.call(audience_segment, user_ids:)
      new(audience_segment).call(user_ids)
    end

    # @param audience_segment [AudienceSegment] the segment to remove users from
    def initialize(audience_segment)
      @audience_segment = audience_segment
    end

    # Deletes the provided users from the AudienceSegment in batches.
    # It touches the segment if any users were successfully deleted.
    #
    # Warning: the joining `SegmentedUsers` records are deleted without triggering any
    # application-defined callbacks. Doing so is the responsibility of the caller.
    #
    # @param user_ids [Array<Integer>] a list of `User` ids to process
    # @return [SegmentedUsers::BulkDelete::Result]
    def call(user_ids)
      return unless @audience_segment.persisted?

      segmented_users = @audience_segment.segmented_users.where(user_id: user_ids)
      valid_user_ids = segmented_users.pluck(:user_id)
      deleted_count = segmented_users.in_batches.delete_all

      @audience_segment.touch if deleted_count.positive?

      Result.new(succeeded: valid_user_ids, failed: user_ids - valid_user_ids)
    end
  end
end
