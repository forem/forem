module Events
  class ManageBroadcastBillboardsWorker
    include Sidekiq::Job
    sidekiq_options queue: :high_priority, retry: 3, lock: :until_executing, on_conflict: :replace

    def perform
      # Look for all active broadcasts
      # An active broadcast event is one where the current time falls 
      # between start_time - 15 minutes and end_time - 5 minutes
      active_events = Event.published.where.not(broadcast_config: 0)
                           .where(
                             "start_time <= :start_cutoff AND (" \
                               "end_time >= :end_cutoff OR " \
                               "(manual_broadcast_end = true AND broadcast_ended_at IS NULL)" \
                             ")",
                             start_cutoff: Time.current + 15.minutes,
                             end_cutoff: Time.current + 5.minutes
                           )
                           .pluck(:id)

      # We must turn ON billboards for active events, and OFF for ALL OTHER EXPIRED event broadcasts.
      # To do this safely:
      # Step 1: Any billboard owned by an event that IS currently active, should be approved.
      newly_approved_count = 0
      if active_events.any?
        Billboard.where(event_id: active_events, approved: false).find_each do |bb|
          bb.update!(approved: true)
          newly_approved_count += 1
          # Manually purge the specific billboard cache when activating since being_taken_down is false
          EdgeCache::PurgeByKey.call(bb.record_key)
        end
        EdgeCache::PurgeByKey.call("main_app_home_page", fallback_paths: "/") if newly_approved_count > 0
      end

      # Step 2: Any billboard owned by a broadcast_config event that is NOT currently active, should be unapproved.
      # That essentially means: event_id is not null, AND event_id is not in active_events.
      billboards_to_disable = Billboard.where.not(event_id: nil)
      billboards_to_disable = billboards_to_disable.where.not(event_id: active_events) if active_events.any?
      
      newly_disabled_count = 0
      billboards_to_disable.where("approved = true OR published = true").find_each do |bb|
        # This update triggers bust_billboard_cache naturally
        bb.update!(approved: false, published: false) 
        newly_disabled_count += 1
      end
      EdgeCache::PurgeByKey.call("main_app_home_page", fallback_paths: "/") if newly_disabled_count > 0
    end
  end
end
