class SegmentedUserRefreshWorker
  include Sidekiq::Job

  sidekiq_options queue: :low_priority

  # Ignore manually-updated segments, remove user if they no longer belong,
  # add the user if they now belong
  def perform(user_or_id)
    user_id = user_or_id.respond_to?(:id) ? user_or_id.id : user_or_id
    automated_segments = AudienceSegment.not_manual
    matching = SegmentedUser.where(user_id: user_id).pluck(:audience_segment_id)

    current_segments = automated_segments.where(id: matching)
    future_segments = automated_segments.each_with_object([]) do |audience_segment, collection|
      collection << audience_segment if audience_segment.includes?(user_id)
    end

    # In current / not in future => delete user from segment
    SegmentedUser
      .where(user_id: user_id)
      .delete_by(audience_segment: (current_segments - future_segments))

    # In future / not in current => add user to segment
    (future_segments - current_segments).each do |audience_segment|
      audience_segment.segmented_users.create! user_id: user_id
    end

    future_segments
  end
end
