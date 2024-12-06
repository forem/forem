# frozen_string_literal: true

module Anyway
  # Parses environment variables and provides
  # method-like access
  class Env
    using RubyNext
    using Anyway::Ext::DeepDup
    using Anyway::Ext::Hash

    include Tracing

    attr_reader :data, :traces, :type_cast

    def initialize(type_cast: AutoCast)
      @type_cast = type_cast
      @data = {}
      @traces = {}
    end

    def clear
      data.clear
      traces.clear
    end

    def fetch(prefix)
      return data[prefix].deep_dup if data.key?(prefix)

      Tracing.capture do
        data[prefix] = parse_env(prefix)
      end.then do |trace|
        traces[prefix] = trace
      end

      data[prefix].deep_dup
    end

    def fetch_with_trace(prefix)
      [fetch(prefix), traces[prefix]]
    end

    private

    def parse_env(prefix)
      match_prefix = "#{prefix}_"
      ENV.each_pair.with_object({}) do |(key, val), data|
        next unless key.start_with?(match_prefix)

        path = key.sub(/^#{prefix}_/, "").downcase

        paths = path.split("__")
        trace!(:env, *paths, key:) { data.bury(type_cast.call(val), *paths) }
      end
    end
  end
end
