# Preloads ActiveRecord model schemas, L1/L2 caches, and database/Redis connections
# across Puma's `before_fork` and `on_worker_boot` lifecycle hooks so newly deployed
# web dynos do not suffer cold-start connection, schema introspection, or cache stampedes
# when live router traffic cuts over (e.g. after Heroku Preboot).
module ServerWarmup
  CORE_MODEL_NAMES = %w[
    User
    Article
    Organization
    Subforem
    Billboard
    BillboardEvent
    Page
    Profile
    Users::Setting
    Users::NotificationSetting
    Role
    Comment
    Reaction
    Tag
    ActsAsTaggableOn::Tagging
    ActsAsTaggableOn::Tag
    Follow
    Identity
    Badge
    BadgeAchievement
    ProfilePin
    ProfileField
    OrganizationMembership
    GithubRepo
    ContextNote
    Ahoy::Visit
    Ahoy::Event
    Notification
    NavigationLink
    Collection
    PodcastEpisode
    Podcast
    Broadcast
    HtmlVariant
    AudienceSegment
    SegmentedUser
    FeedConfig
    RecommendedArticlesList
    Settings::General
    Settings::UserExperience
    Settings::Community
    Settings::Authentication
    Settings::Smtp
    Settings::RateLimit
    Settings::Campaign
    Flipper::Adapters::ActiveRecord::Feature
    Flipper::Adapters::ActiveRecord::Gate
  ].freeze

  AUXILIARY_TABLES = %w[
    users_roles
    flipper_features
    flipper_gates
    taggings
  ].freeze

  DEFAULT_PREBOOT_KEEPALIVE_INTERVAL = 25

  @keepalive_mutex = Mutex.new
  @keepalive_thread = nil
  @shutdown_queue = nil
  @traffic_received = false
  @traffic_hook_registered = false

  class << self
    def warmup_enabled?
      return ENV["PUMA_WARMUP_ENABLED"] == "true" if ENV.key?("PUMA_WARMUP_ENABLED")

      defined?(Rails) && Rails.env.production?
    end

    # Runs in the Puma master process after `preload_app!` and immediately before `nakayoshi_fork`
    # and worker forking. Preloads ActiveRecord schemas, primary keys, generated attribute methods,
    # and L1 in-memory caches (`MemoryFirstCache` & `Flipper`) so Copy-on-Write shares them across
    # all workers, then cleanly disconnects all parent sockets before `fork`.
    def before_fork
      return unless warmup_enabled?

      preload_model_schemas!
      warm_in_memory_caches!
    rescue StandardError => e
      log_error("before_fork warmup failed", e)
    ensure
      disconnect_parent_connections! if warmup_enabled?
    end

    # Runs in each forked Puma worker process on boot (inside Heroku's Preboot window).
    # Establishes the worker's ActiveRecord connection pool, pre-connects and initializes
    # PostgreSQL OID type maps for worker threads, warms the Redis cache client, refreshes
    # L1 caches, and keeps idle connections warm until live traffic arrives.
    def on_worker_boot
      ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
      return unless warmup_enabled?

      @traffic_received = false
      register_traffic_hook!
      warm_database_connections!
      warm_redis_cache_connection!
      warm_in_memory_caches!
      start_preboot_keepalive!
    rescue StandardError => e
      log_error("on_worker_boot warmup failed", e)
    ensure
      clear_request_store!
    end

    def on_worker_shutdown
      stop_preboot_keepalive!
    rescue StandardError => e
      log_error("on_worker_shutdown cleanup failed", e)
    end

    def mark_traffic_received!
      @traffic_received = true
    end

    def traffic_received?
      @traffic_received
    end

    def reset_state!
      stop_preboot_keepalive!
      @traffic_received = false
    end

    def preload_model_schemas!
      return unless database_available?

      models_to_preload.each do |model|
        preload_single_model_schema(model)
      end

      preload_auxiliary_tables!
    rescue StandardError => e
      log_error("Model schema preload failed", e)
    end

    def warm_database_connections!(target_count = worker_thread_count)
      return 0 unless defined?(ActiveRecord::Base)

      pool = ActiveRecord::Base.connection_pool
      count = [target_count.to_i, pool.size].min
      return 0 if count <= 0

      checked_out = []
      begin
        count.times do
          break if @traffic_received

          conn = pool.checkout
          conn.verify!
          checked_out << conn
        end
        checked_out.size
      ensure
        checked_out.each { |conn| pool.checkin(conn) }
      end
    rescue StandardError => e
      log_error("Database connection pool warmup failed", e)
      0
    end

    def warm_redis_cache_connection!
      return unless defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache

      if Rails.cache.respond_to?(:redis)
        redis_client = Rails.cache.redis
        if redis_client.respond_to?(:with)
          redis_client.with(&:ping)
        elsif redis_client.respond_to?(:ping)
          redis_client.ping
        end
      else
        Rails.cache.read("subforem_default_id")
      end
    rescue StandardError => e
      log_error("Redis cache connection warmup failed", e)
    end

    def warm_in_memory_caches!
      return unless database_available?

      warm_flipper_cache!
      warm_subforem_caches!
    rescue StandardError => e
      log_error("In-memory cache warmup failed", e)
    ensure
      clear_request_store!
    end

    def warm_flipper_cache!
      return unless defined?(Flipper)

      preloaded = Flipper.respond_to?(:preload_all) ? Flipper.preload_all : []
      if Flipper.respond_to?(:preload) && preloaded.present?
        Flipper.preload(Array(preloaded).map { |f| f.key.to_sym })
      end

      if defined?(MemoryFirstCache) && defined?(FeatureFlag) && FeatureFlag.respond_to?(:all)
        MemoryFirstCache.fetch("enabled_global_feature_flags", redis_expires_in: 10.minutes) do
          FeatureFlag.all.select { |_, state| state == :on }.keys.join(" ")
        end
      end
    rescue StandardError => e
      log_error("Flipper cache warmup failed", e)
    end

    def warm_subforem_caches!
      return unless defined?(Subforem) && Subforem.table_exists?

      Subforem.cached_default_id
      Subforem.cached_root_id
      Subforem.cached_default_domain
      Subforem.cached_root_domain
      Subforem.cached_domains
      all_domains = Subforem.cached_all_domains
      Subforem.cached_id_to_domain_hash
      Subforem.cached_discoverable_ids
      Subforem.cached_postable_array
      Subforem.cached_misc_subforem_id

      domains_to_warm = Array(all_domains).dup
      domains_to_warm << ApplicationConfig.app_domain_no_port if defined?(ApplicationConfig)
      if defined?(Settings::General) && Settings::General.table_exists?
        domains_to_warm << Settings::General.app_domain
      end

      domains_to_warm.compact.map(&:to_s).reject(&:empty?).uniq.each do |domain|
        Subforem.cached_id_by_domain(domain)
      end
    rescue StandardError => e
      log_error("Subforem cache warmup failed", e)
    end

    def disconnect_parent_connections!
      clear_request_store!
      if defined?(ActiveRecord::Base)
        ActiveRecord::Base.connection_handler.clear_all_connections!(:all)
      end
      close_redis_cache_connection!
    rescue StandardError => e
      log_error("Parent connection cleanup failed", e)
    end

    # Keeps the worker's pre-warmed database connections and L1 caches warm across
    # Heroku's ~160s Preboot window so `AR Pool Reaper` (`idle_timeout: 60`) does not
    # disconnect idle connections before router cutover. Automatically exits as soon
    # as live traffic arrives or the Preboot window elapses.
    def start_preboot_keepalive!(
      duration_seconds: preboot_keepalive_seconds,
      interval_seconds: preboot_keepalive_interval
    )
      stop_preboot_keepalive!
      return if duration_seconds.to_i <= 0 || interval_seconds.to_f <= 0

      @keepalive_mutex.synchronize do
        queue = Thread::Queue.new
        @shutdown_queue = queue
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + duration_seconds.to_f

        @keepalive_thread = Thread.new do
          Thread.current.name = "puma-preboot-keepalive" if Thread.current.respond_to?(:name=)
          run_preboot_keepalive_loop(queue, deadline, interval_seconds.to_f)
        end
      end
    end

    def stop_preboot_keepalive!
      thread = nil
      @keepalive_mutex.synchronize do
        @shutdown_queue&.push(:stop)
        thread = @keepalive_thread
        @keepalive_thread = nil
        @shutdown_queue = nil
      end
      thread&.join(1)
    end

    private

    def run_preboot_keepalive_loop(queue, deadline, interval_seconds)
      loop do
        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        break if remaining <= 0 || @traffic_received

        wait_time = [interval_seconds, remaining].min
        stopped = wait_for_stop_signal(queue, wait_time)
        break if stopped || @traffic_received
        break if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

        warm_database_connections!
        warm_flipper_cache!
      end
    rescue StandardError => e
      log_error("Preboot keepalive exited unexpectedly", e)
    ensure
      clear_request_store!
    end

    def wait_for_stop_signal(queue, timeout_seconds)
      queue.pop(timeout: timeout_seconds) == :stop
    rescue StandardError
      true
    end

    def register_traffic_hook!
      return if @traffic_hook_registered
      return unless defined?(Rails) && Rails.respond_to?(:application) &&
        Rails.application && Rails.application.respond_to?(:executor)

      Rails.application.executor.to_run do
        ServerWarmup.mark_traffic_received!
      end
      @traffic_hook_registered = true
    rescue StandardError => e
      log_error("Traffic hook registration failed", e)
    end

    def models_to_preload
      core_models = CORE_MODEL_NAMES.filter_map(&:safe_constantize)
      descendants = if defined?(ActiveRecord::Base)
                      ActiveRecord::Base.descendants
                    else
                      []
                    end
      (core_models | descendants).reject(&:abstract_class?)
    end

    def preload_single_model_schema(model)
      return if model.abstract_class? || !model.table_exists?

      model.load_schema
      model.primary_key
      model.define_attribute_methods
    rescue StandardError => e
      log_error("Schema preload failed for #{model}", e)
    end

    def preload_auxiliary_tables!
      schema_cache = ActiveRecord::Base.connection_pool.schema_cache
      AUXILIARY_TABLES.each do |table_name|
        next unless schema_cache.data_source_exists?(table_name)

        schema_cache.primary_keys(table_name)
        schema_cache.columns_hash(table_name)
      rescue StandardError => e
        log_error("Auxiliary table preload failed for #{table_name}", e)
      end
    end

    def database_available?
      return false unless defined?(ActiveRecord::Base)

      ActiveRecord::Base.with_connection(&:active?)
    rescue StandardError => e
      log_error("Database unavailable for warmup", e)
      false
    end

    def close_redis_cache_connection!
      return unless defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache.respond_to?(:redis)

      redis_client = Rails.cache.redis
      if redis_client.respond_to?(:with)
        redis_client.with { |conn| conn.close if conn.respond_to?(:close) }
      elsif redis_client.respond_to?(:close)
        redis_client.close
      end
    rescue StandardError => e
      log_error("Redis connection close failed", e)
    end

    def clear_request_store!
      RequestStore.clear! if defined?(RequestStore) && RequestStore.respond_to?(:clear!)
    rescue StandardError
      nil
    end

    def worker_thread_count
      ENV.fetch("RAILS_MAX_THREADS", 5).to_i
    end

    def preboot_keepalive_seconds
      default_seconds = defined?(Rails) && Rails.env.production? ? 210 : 0
      ENV.fetch("PUMA_PREBOOT_KEEPALIVE_SECONDS", default_seconds).to_i
    end

    def preboot_keepalive_interval
      ENV.fetch("PUMA_PREBOOT_KEEPALIVE_INTERVAL", DEFAULT_PREBOOT_KEEPALIVE_INTERVAL).to_f
    end

    def log_error(context, error)
      return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

      Rails.logger.error("[ServerWarmup] #{context}: #{error.class}: #{error.message}")
    end
  end
end
