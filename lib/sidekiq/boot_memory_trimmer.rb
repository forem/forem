module Sidekiq
  # Load-time memory reductions that only apply to Sidekiq server processes (see the
  # `Sidekiq.configure_server` block in config/initializers/sidekiq.rb).
  #
  # Sidekiq runs as a single process (no forking), so eager loading code that jobs never touch
  # buys no copy-on-write sharing; it only adds resident memory to every Sidekiq dyno.
  module BootMemoryTrimmer
    # Code that only serves web requests. It stays fully autoloadable in Sidekiq (for example,
    # liquid tags call `ApplicationController.render`), it just isn't loaded up front at boot.
    WEB_ONLY_EAGER_LOAD_EXCLUSIONS = %w[
      app/controllers
      app/controllers/concerns
      app/policies
      app/serializers
      app/forms
    ].freeze

    # NOTE: `::Rails` is required here; a bare `Rails` inside `module Sidekiq` resolves to the
    # `Sidekiq::Rails` railtie, whose `root` is the sidekiq gem's directory.
    def self.skip_eager_loading_web_only_code!(autoloader: ::Rails.autoloaders.main, root: ::Rails.root)
      autoloader.do_not_eager_load(*WEB_ONLY_EAGER_LOAD_EXCLUSIONS.map { |dir| root.join(dir) })
    end

    # Bootsnap's load path cache only speeds up `require` during boot. Zeitwerk autoloads by absolute
    # path and doesn't need it, so Sidekiq can free it once booted. Any later `require` falls back to
    # Ruby's regular lookup. Bootsnap's compile cache is unaffected.
    def self.release_bootsnap_load_path_cache!(bootsnap: (Bootsnap if defined?(Bootsnap)))
      bootsnap.unload_cache! if bootsnap.respond_to?(:unload_cache!)
    end
  end
end
