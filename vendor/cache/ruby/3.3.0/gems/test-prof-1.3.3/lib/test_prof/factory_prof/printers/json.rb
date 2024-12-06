# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf::FactoryProf
  module Printers
    module Json  # :nodoc: all
      class << self
        using TestProf::FloatDuration
        include TestProf::Logging

        def dump(result, start_time:)
          return log(:info, "No factories detected") if result.raw_stats == {}

          outpath = TestProf.artifact_path("test-prof.result.json")
          File.write(outpath, convert_stats(result, start_time).to_json)

          log :info, "Profile results to JSON: #{outpath}"
        end

        def convert_stats(result, start_time)
          total_run_time = TestProf.now - start_time
          total_count = result.stats.sum { |stat| stat[:total_count] }
          total_top_level_count = result.stats.sum { |stat| stat[:top_level_count] }
          total_time = result.stats.sum { |stat| stat[:top_level_time] }
          total_uniq_factories = result.stats.map { |stat| stat[:name] }.uniq.count

          {
            total_count: total_count,
            total_top_level_count: total_top_level_count,
            total_time: total_time.duration,
            total_run_time: total_run_time.duration,
            total_uniq_factories: total_uniq_factories,

            stats: result.stats
          }
        end
      end
    end
  end
end
