module Sidekiq
  # Gives every Sidekiq job a fresh RequestStore, the way RequestStore::Middleware does for web requests,
  # and seeds `:default_subforem_id` so background lookups (e.g. `Settings::Base`, `URL`) resolve against
  # the default subforem when no job-specific `:subforem_id` is set.
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
      default_subforem_id = default_subforem_id_if_available
      RequestStore.store[:default_subforem_id] = default_subforem_id if default_subforem_id
      yield
    ensure
      RequestStore.end!
      RequestStore.clear!
    end

    private

    def default_subforem_id_if_available
      return unless defined?(Subforem)

      Subforem.cached_default_id
    rescue StandardError
      nil
    end
  end
end
