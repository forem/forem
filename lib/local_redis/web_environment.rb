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
    MALLOC_CONF_PATTERN = /\A[a-zA-Z0-9_]+:[a-zA-Z0-9_]+(?:,[a-zA-Z0-9_]+:[a-zA-Z0-9_]+)*\z/

    POSITIVE_INTEGER_GC_VARS = {
      "WEB_RUBY_GC_HEAP_INIT_SLOTS" => "RUBY_GC_HEAP_INIT_SLOTS",
      "WEB_RUBY_GC_HEAP_FREE_SLOTS" => "RUBY_GC_HEAP_FREE_SLOTS",
      "WEB_RUBY_GC_HEAP_GROWTH_MAX_SLOTS" => "RUBY_GC_HEAP_GROWTH_MAX_SLOTS",
      "WEB_RUBY_GC_MALLOC_LIMIT" => "RUBY_GC_MALLOC_LIMIT",
      "WEB_RUBY_GC_MALLOC_LIMIT_MAX" => "RUBY_GC_MALLOC_LIMIT_MAX",
      "WEB_RUBY_GC_OLDMALLOC_LIMIT" => "RUBY_GC_OLDMALLOC_LIMIT",
      "WEB_RUBY_GC_OLDMALLOC_LIMIT_MAX" => "RUBY_GC_OLDMALLOC_LIMIT_MAX"
    }.freeze

    POSITIVE_FLOAT_GC_VARS = {
      "WEB_RUBY_GC_HEAP_GROWTH_FACTOR" => "RUBY_GC_HEAP_GROWTH_FACTOR",
      "WEB_RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO" => "RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO",
      "WEB_RUBY_GC_HEAP_FREE_SLOTS_GOAL_RATIO" => "RUBY_GC_HEAP_FREE_SLOTS_GOAL_RATIO",
      "WEB_RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO" => "RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO",
      "WEB_RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR" => "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR",
      "WEB_RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR" => "RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR",
      "WEB_RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR" => "RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR"
    }.freeze

    YJIT_INTEGER_FLAGS = {
      "WEB_YJIT_EXEC_MEM_SIZE" => "--yjit-exec-mem-size",
      "WEB_YJIT_CALL_THRESHOLD" => "--yjit-call-threshold",
      "WEB_YJIT_COLD_THRESHOLD" => "--yjit-cold-threshold"
    }.freeze

    class << self
      def build(env = ENV)
        overrides = {}
        apply_gc_overrides(env, overrides)
        apply_malloc_conf_override(env, overrides)
        apply_rubyopt_override(env, overrides)
        overrides
      end

      private

      def apply_gc_overrides(env, overrides)
        POSITIVE_INTEGER_GC_VARS.each do |source_key, target_key|
          value = read_matched_value(env, source_key, POSITIVE_INTEGER_PATTERN, "a positive integer")
          overrides[target_key] = value if value
        end

        POSITIVE_FLOAT_GC_VARS.each do |source_key, target_key|
          value = read_matched_value(env, source_key, POSITIVE_FLOAT_PATTERN, "a positive number")
          overrides[target_key] = value if value
        end
      end

      def apply_malloc_conf_override(env, overrides)
        value = read_matched_value(env, "WEB_MALLOC_CONF", MALLOC_CONF_PATTERN, "key:value pairs")
        overrides["MALLOC_CONF"] = value if value
      end

      def apply_rubyopt_override(env, overrides)
        web_rubyopt = stripped_value(env, "WEB_RUBYOPT")
        yjit_flags = collect_yjit_flags(env)
        return if web_rubyopt.nil? && yjit_flags.empty?

        current_rubyopt = stripped_value(env, "RUBYOPT").to_s
        base_rubyopt = if web_rubyopt
                         bundler_tokens = current_rubyopt.split.select { |t| t.include?("bundler/setup") }
                         (bundler_tokens | web_rubyopt.split).join(" ")
                       else
                         current_rubyopt
                       end
        candidate = merge_rubyopt(base_rubyopt, yjit_flags)
        return if candidate.empty?

        if valid_rubyopt?(candidate)
          overrides["RUBYOPT"] = candidate
        else
          warn "LocalRedis::WebEnvironment ignoring invalid RUBYOPT candidate: #{candidate.inspect}"
        end
      end

      def collect_yjit_flags(env)
        YJIT_INTEGER_FLAGS.each_with_object({}) do |(env_key, flag_prefix), flags|
          value = read_matched_value(env, env_key, POSITIVE_INTEGER_PATTERN, "a positive integer")
          flags[flag_prefix] = "#{flag_prefix}=#{value}" if value
        end
      end

      def merge_rubyopt(base_rubyopt, yjit_flags)
        tokens = base_rubyopt.split
        return tokens.join(" ") if yjit_flags.empty?

        tokens.reject! { |token| yjit_flags.each_key.any? { |prefix| token.start_with?("#{prefix}=") } }
        unless tokens.include?("--yjit") || tokens.include?("--yjit-disable")
          tokens << "--yjit-disable"
        end
        tokens.concat(yjit_flags.values)
        tokens.join(" ")
      end

      def valid_rubyopt?(candidate)
        system({ "RUBYOPT" => candidate }, RbConfig.ruby, "-e", "", out: File::NULL, err: File::NULL) == true
      rescue SystemCallError
        false
      end

      def read_matched_value(env, key, pattern, expected_description)
        value = stripped_value(env, key)
        return if value.nil?
        return value if pattern.match?(value)

        warn "LocalRedis::WebEnvironment ignoring #{key}=#{value.inspect} (expected #{expected_description})"
        nil
      end

      def stripped_value(env, key)
        raw = env[key].to_s.strip
        raw.empty? ? nil : raw
      end
    end
  end
end
