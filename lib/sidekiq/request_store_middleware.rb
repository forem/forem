module Sidekiq
  # Gives every Sidekiq job a fresh RequestStore, the way RequestStore::Middleware does for web requests.
  #
  # RequestStore is a Thread.current hash and Sidekiq reuses its threads, so without this anything
  # memoized there (notably Settings::Base's per-class settings hash) lives for the life of the thread.
  # Settings saved by an admin would then never reach a Sidekiq thread that had already read them,
  # until the process restarted, and values could leak from one job to the next.
  #
  # This only clears the store; it deliberately does not seed subforem context
  # (:subforem_id, :default_subforem_id, ...) because article scopes, feeds and URL helpers branch
  # on those keys and have always run with them unset in jobs.
  class RequestStoreMiddleware
    def call(_worker, _job, _queue)
      RequestStore.clear!
      RequestStore.begin!
      yield
    ensure
      RequestStore.end!
      RequestStore.clear!
    end
  end
end
