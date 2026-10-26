module Sidekiq
  # Gives every Sidekiq job a fresh RequestStore, the way RequestStore::Middleware does for web requests.
  #
  # RequestStore is a Thread.current hash and Sidekiq reuses its threads. The request_store
  # gem's only non-Rack reset (an ActiveSupport::Reloader to_complete hook) never fires in production,
  # because the reloader's check is `false` when code reloading is disabled. Without this, anything
  # memoized in RequestStore (notably Settings::Base's per-class settings hashes) lives as long as the
  # thread, so admin edits never reach a Sidekiq thread that has already read them until the process
  # restarts, and values can leak from one job to the next.
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
