require "rbconfig"

module LocalRedis
  # Builds optional, validated Ruby VM, YJIT, GC, and jemalloc environment
  # overrides scoped strictly to the Puma web server process launched by `bin/web`.
  #
  # All settings are opt-in via `WEB_*` environment variables (nothing is enabled
  # by default) so non-web dynos (e.g. `sidekiq_worker` on Standard-2X or `release`
  # on Standard-1X) and local Redis helper processes do not inherit large-dyno settings.
  module WebEnvironment
    POSITIVE_INTEGER_PATTERN = /\A[1-9]\d*\z/
    POSITIVE_FLOAT_PATTERN = /\A(?:0\.\d+|[1-9]\d*(?:\.\d+)?)\z/
    MALLOC_CONF_OPTION_PATTERN = /(?:(?:dirty|muzzy)_decay_ms:-1|[a-zA-Z0-9_]+:[a-zA-Z0-9_]+)/
    MALLOC_CONF_PATTERN = /\A#{MALLOC_CONF_OPTION_PATTERN}(?:,#{MALLOC_CONF_OPTION_PATTERN})*\z/
    RUBYOPT_VALIDATION_TIMEOUT = 2.0

    POSITIVE_INTEGER_GC_VARS = {
      "WEB_RUBY_GC_HEAP_INIT_SLOTS" => "RUBY_GC_HEAP_0_INIT_SLOTS",
      "WEB_RUBY_GC_HEAP_0_INIT_SLOTS" => "RUBY_GC_HEAP_0_INIT_SLOTS",
      "WEB_RUBY_GC_HEAP_1_INIT_SLOTS" => "RUBY_GC_HEAP_1_INIT_SLOTS",
      "WEB_RUBY_GC_HEAP_2_INIT_SLOTS" => "RUBY_GC_HEAP_2_INIT_SLOTS",
      "WEB_RUBY_GC_HEAP_3_INIT_SLOTS" => "RUBY_GC_HEAP_3_INIT_SLOTS",
      "WEB_RUBY_GC_HEAP_4_INIT_SLOTS" => "RUBY_GC_HEAP_4_INIT_SLOTS",
      "WEB_RUBY_GC_HEAP_FREE_SLOTS" => "RUBY_GC_HEAP_FREE_SLOTS",
      "WEB_RUBY_GC_HEAP_GROWTH_MAX_SLOTS" => "RUBY_GC_HEAP_GROWTH_MAX_SLOTS",
      "WEB_RUBY_GC_MALLOC_LIMIT" => "RUBY_GC_MALLOC_LIMIT",
      "WEB_RUBY_GC_MALLOC_LIMIT_MAX" => "RUBY_GC_MALLOC_LIMIT_MAX",
      "WEB_RUBY_GC_OLDMALLOC_LIMIT" => "RUBY_GC_OLDMALLOC_LIMIT",
      "WEB_RUBY_GC_OLDMALLOC_LIMIT_MAX" => "RUBY_GC_OLDMALLOC_LIMIT_MAX"
    }.freeze

    GROWTH_FACTOR_GC_VARS = {
      "WEB_RUBY_GC_HEAP_GROWTH_FACTOR" => "RUBY_GC_HEAP_GROWTH_FACTOR",
      "WEB_RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR" => "RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR",
      "WEB_RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR" => "RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR"
    }.freeze

    RATIO_GC_VARS = {
      "WEB_RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO" => "RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO",
      "WEB_RUBY_GC_HEAP_FREE_SLOTS_GOAL_RATIO" => "RUBY_GC_HEAP_FREE_SLOTS_GOAL_RATIO",
      "WEB_RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO" => "RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO"
    }.freeze

    POSITIVE_FLOAT_GC_VARS = {
      "WEB_RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR" => "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR"
    }.freeze

    YJIT_INTEGER_FLAGS = {
      "WEB_YJIT_EXEC_MEM_SIZE" => "--yjit-exec-mem-size",
      "WEB_YJIT_CALL_THRESHOLD" => "--yjit-call-threshold",
      "WEB_YJIT_COLD_THRESHOLD" => "--yjit-cold-threshold"
    }.freeze

    class << self
      # Builds a hash of validated environment variable overrides for the web process.
      #
      # @param env [Hash, ENV] source environment variables
      # @return [Hash<String, String>] validated environment overrides for Puma
      def build(env = ENV)
        overrides = {}
        apply_gc_overrides(env, overrides)
        apply_malloc_conf_override(env, overrides)
        apply_rubyopt_override(env, overrides)
        overrides
      end

      private

      # Applies validated `WEB_RUBY_GC_*` overrides into `overrides`.
      def apply_gc_overrides(env, overrides)
        POSITIVE_INTEGER_GC_VARS.each do |source_key, target_key|
          value = read_matched_value(env, source_key, POSITIVE_INTEGER_PATTERN, "a positive integer")
          overrides[target_key] = value if value
        end

        GROWTH_FACTOR_GC_VARS.each do |source_key, target_key|
          value = read_bounded_float(env, source_key, "a number greater than 1.0") { |num| num > 1.0 }
          overrides[target_key] = value if value
        end

        RATIO_GC_VARS.each do |source_key, target_key|
          value = read_bounded_float(env, source_key, "a ratio between 0.0 and 1.0 (exclusive)") do |num|
            num > 0.0 && num < 1.0
          end
          overrides[target_key] = value if value
        end

        POSITIVE_FLOAT_GC_VARS.each do |source_key, target_key|
          value = read_bounded_float(env, source_key, "a positive number") { |num| num > 0.0 }
          overrides[target_key] = value if value
        end
      end

      # Applies a validated `WEB_MALLOC_CONF` override into `overrides`.
      def apply_malloc_conf_override(env, overrides)
        value = read_matched_value(env, "WEB_MALLOC_CONF", MALLOC_CONF_PATTERN, "key:value pairs")
        overrides["MALLOC_CONF"] = value if value
      end

      # Applies validated `WEB_RUBYOPT` and `WEB_YJIT_*` flags into `overrides["RUBYOPT"]`.
      def apply_rubyopt_override(env, overrides)
        web_rubyopt = stripped_value(env, "WEB_RUBYOPT")
        yjit_flags = collect_yjit_flags(env)
        return if web_rubyopt.nil? && yjit_flags.empty?

        current_rubyopt = stripped_value(env, "RUBYOPT").to_s
        base_rubyopt = if web_rubyopt
                         merge_bundler_and_web_rubyopt(current_rubyopt, web_rubyopt)
                       else
                         current_rubyopt
                       end
        candidate = merge_rubyopt(base_rubyopt, yjit_flags, env)
        return if candidate.empty?

        if valid_rubyopt?(candidate)
          overrides["RUBYOPT"] = candidate
        else
          warn "LocalRedis::WebEnvironment ignoring invalid RUBYOPT candidate: #{candidate.inspect}"
        end
      end

      # Preserves Bundler require tokens (both `-rbundler/setup` and `-r bundler/setup`)
      # from `current_rubyopt` when building the base `WEB_RUBYOPT` string.
      def merge_bundler_and_web_rubyopt(current_rubyopt, web_rubyopt)
        bundler_tokens = extract_bundler_tokens(current_rubyopt)
        web_tokens = web_rubyopt.split
        return web_tokens.join(" ") if bundler_tokens.empty?
        return web_tokens.join(" ") if web_tokens.any? { |token| token.include?("bundler/setup") }

        (bundler_tokens + web_tokens).join(" ")
      end

      # Extracts `-r.../bundler/setup` or separated `-r .../bundler/setup` tokens from `rubyopt`.
      def extract_bundler_tokens(rubyopt)
        tokens = rubyopt.split
        extracted = []
        tokens.each_with_index do |token, index|
          next unless token.include?("bundler/setup")

          extracted << "-r" if token != "-r" && !token.start_with?("-r") && index.positive? && tokens[index - 1] == "-r"
          extracted << token
        end
        extracted
      end

      # Collects validated `WEB_YJIT_*` flags as `--yjit-*=<N>` CLI tokens.
      def collect_yjit_flags(env)
        YJIT_INTEGER_FLAGS.each_with_object({}) do |(env_key, flag_prefix), flags|
          value = read_matched_value(env, env_key, POSITIVE_INTEGER_PATTERN, "a positive integer")
          flags[flag_prefix] = "#{flag_prefix}=#{value}" if value
        end
      end

      # Merges `yjit_flags` into `base_rubyopt`, preserving existing YJIT enablement state.
      def merge_rubyopt(base_rubyopt, yjit_flags, env)
        tokens = base_rubyopt.split
        return tokens.join(" ") if yjit_flags.empty?

        yjit_already_enabled = yjit_enabled?(tokens, env)
        tokens.reject! { |token| yjit_flags.each_key.any? { |prefix| token.start_with?("#{prefix}=") } }
        unless yjit_already_enabled || tokens.include?("--yjit-disable")
          tokens << "--yjit-disable"
        end
        tokens.concat(yjit_flags.values)
        tokens.join(" ")
      end

      # Determines whether YJIT is already enabled by existing `RUBYOPT` tokens or `RUBY_YJIT_ENABLE=1`.
      def yjit_enabled?(tokens, env)
        return false if tokens.include?("--yjit-disable")

        tokens.any? { |token| token == "--yjit" || token.start_with?("--yjit-") } ||
          stripped_value(env, "RUBY_YJIT_ENABLE") == "1"
      end

      # Verifies that the Ruby VM accepts `candidate` as `RUBYOPT` within a bounded timeout.
      def valid_rubyopt?(candidate, timeout: RUBYOPT_VALIDATION_TIMEOUT)
        pid = Process.spawn({ "RUBYOPT" => candidate }, RbConfig.ruby, "-e", "", out: File::NULL, err: File::NULL)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
        loop do
          waited_pid, status = Process.waitpid2(pid, Process::WNOHANG)
          return status.success? if waited_pid

          if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            terminate_validator(pid)
            return false
          end

          sleep 0.01
        end
      rescue SystemCallError
        false
      ensure
        terminate_validator(pid) if pid
      end

      # Ensures the validation child process is terminated and reaped.
      def terminate_validator(pid)
        Process.kill("KILL", pid)
        Process.waitpid(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end

      # Reads and validates a floating-point environment variable against both syntax and range bounds.
      def read_bounded_float(env, key, expected_description)
        value = stripped_value(env, key)
        return if value.nil?

        if POSITIVE_FLOAT_PATTERN.match?(value) && yield(value.to_f)
          return value
        end

        warn "LocalRedis::WebEnvironment ignoring #{key}=#{value.inspect} (expected #{expected_description})"
        nil
      end

      # Reads and validates an environment variable against `pattern`.
      def read_matched_value(env, key, pattern, expected_description)
        value = stripped_value(env, key)
        return if value.nil?
        return value if pattern.match?(value)

        warn "LocalRedis::WebEnvironment ignoring #{key}=#{value.inspect} (expected #{expected_description})"
        nil
      end

      # Returns the stripped string value for `key` or `nil` when absent/blank.
      def stripped_value(env, key)
        raw = env[key].to_s.strip
        raw.empty? ? nil : raw
      end
    end
  end
end
