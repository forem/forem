module Events
  class ManageBroadcastBillboardsWorker
    include Sidekiq::Job
    sidekiq_options queue: :high_priority, retry: 3

    def perform
      # Look for all active broadcasts
      # An active broadcast event is one where the current time falls 
      # between start_time - 15 minutes and end_time + 5 minutes allowing wiggle room
      active_events = Event.published.where.not(broadcast_config: 0)
                           .where("start_time <= ? AND end_time >= ?", Time.current + 15.minutes, Time.current - 5.minutes)
                           .pluck(:id)

      # We must turn ON billboards for active events, and OFF for ALL OTHER EXPIRED event broadcasts.
      # To do this safely:
      # Step 1: Any billboard owned by an event that IS currently active, should be approved.
      if active_events.any?
        newly_approved_count = Billboard.where(event_id: active_events, approved: false).update_all(approved: true)
        if newly_approved_count > 0
          EdgeCache::PurgeByKey.call("main_app_home_page", fallback_paths: "/")
          Billboard.where(event_id: active_events).find_each do |bb|
            EdgeCache::PurgeByKey.call(bb.record_key)
          end
        end
      end

      # Step 2: Any billboard owned by a broadcast_config event that is NOT currently active, should be unapproved.
      # That essentially means: event_id is not null, AND event_id is not in active_events.
      billboards_to_disable = Billboard.where.not(event_id: nil)
      billboards_to_disable = billboards_to_disable.where.not(event_id: active_events) if active_events.any?
      
      newly_disabled_count = billboards_to_disable.where(approved: true).update_all(approved: false)
      if newly_disabled_count > 0
        EdgeCache::PurgeByKey.call("main_app_home_page", fallback_paths: "/")
        billboards_to_disable.find_each do |bb|
          EdgeCache::PurgeByKey.call(bb.record_key)
        end
      end
    end
  end
end
