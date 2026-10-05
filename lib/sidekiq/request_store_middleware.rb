module Sidekiq
  # Gives every Sidekiq job a fresh RequestStore, the way RequestStore::Middleware does for web requests,
  # and opts the job into reading the default subforem's settings.
  #
  # Fresh store: RequestStore is a Thread.current hash and Sidekiq reuses its threads. The request_store
  # gem's only non-Rack reset (an ActiveSupport::Reloader to_complete hook) never fires in production,
  # because the reloader's check is `false` when code reloading is disabled. Without this, anything
  # memoized in RequestStore (notably Settings::Base's per-class settings hashes) lives as long as the
  # thread, so admin edits never reach a Sidekiq thread that has already read them until the process
  # restarts, and values can leak from one job to the next.
  #
  # Default subforem settings: admin edits made in the web UI are saved on the default subforem's rows,
  # but a job has no request context, so without the flag it reads only global rows. See
  # Settings::Base.resolve_read_subforem_id.
  #
  # This deliberately does not seed :subforem_id / :default_subforem_id: article scopes, feeds, URL
  # helpers and Article#set_default_subforem_id branch on those keys and have always run with them
  # unset in jobs. The flag only affects settings reads.
  class RequestStoreMiddleware
    def call(_worker, _job, _queue)
      RequestStore.clear!
      RequestStore.begin!
      RequestStore.store[Settings::Base::DEFAULT_SUBFOREM_FALLBACK_FLAG] = true
      yield
    ensure
      RequestStore.end!
      RequestStore.clear!
    end
  end
end
