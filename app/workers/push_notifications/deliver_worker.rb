module PushNotifications
  class DeliverWorker
    include Sidekiq::Job

    # Rpush.push mutates process-global singletons (Rpush::Daemon::AppRunner,
    # Feeder, Synchronizer) and waits up to 60s (CLIENT_JOIN_TIMEOUT) for APNs
    # HTTP/2 streams. Keep lock_ttl above CLIENT_JOIN_TIMEOUT and serialize
    # in-process execution with a mutex so overlapping jobs never close active
    # NetHttp2::Client sockets mid-batch.
    PUSH_MUTEX = Mutex.new

    sidekiq_options queue: :medium_priority,
                    retry: 10,
                    lock: :until_expired,
                    lock_ttl: 120,
                    on_conflict: :log

    def perform
      # Deliver all pending Push Notifications
      PUSH_MUTEX.synchronize do
        Rpush.push
      end
    end
  end
end
