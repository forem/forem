module PushNotifications
  class DeliverWorker
    include Sidekiq::Job

    # Rpush.push mutates process-global singletons (Rpush::Daemon::AppRunner,
    # Feeder, Synchronizer) and waits up to 60s (CLIENT_JOIN_TIMEOUT) for APNs
    # HTTP/2 streams. Use `lock: :until_and_while_executing` with
    # `on_conflict: { client: :log, server: :reschedule }` so enqueues coalesce
    # while a job is scheduled/queued, the client lock releases as soon as the
    # server begins executing (allowing notifications created mid-drain to
    # schedule a follow-up job), and any server-side runtime overlap is
    # rescheduled instead of dropped.
    PUSH_MUTEX = Mutex.new

    sidekiq_options queue: :medium_priority,
                    retry: 10,
                    lock: :until_and_while_executing,
                    lock_ttl: 120,
                    on_conflict: { client: :log, server: :reschedule }

    # Delivers all pending Rpush notifications while holding PUSH_MUTEX so
    # in-process Sidekiq threads never overlap Rpush.push executions.
    def perform
      PUSH_MUTEX.synchronize do
        Rpush.push
      end
    end
  end
end
