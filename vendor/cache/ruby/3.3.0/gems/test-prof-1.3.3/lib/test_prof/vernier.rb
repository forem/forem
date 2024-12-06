# frozen_string_literal: true

module TestProf
  # Vernier wrapper.
  #
  # Has 2 modes: global and per-example.
  #
  # Example:
  #
  #   # To activate global profiling you can use env variable
  #   TEST_VERNIER=1 rspec ...
  #
  # To profile a specific examples add :vernier tag to it:
  #
  #   it "is doing heavy stuff", :vernier do
  #     ...
  #   end
  #
  module Vernier
    # Vernier configuration
    class Configuration
      attr_accessor :mode, :target, :interval

      def initialize
        @mode = ENV.fetch("TEST_VERNIER_MODE", :wall).to_sym
        @target = (ENV["TEST_VERNIER"] == "boot") ? :boot : :suite

        sample_interval = ENV["TEST_VERNIER_INTERVAL"].to_i
        @interval = (sample_interval > 0) ? sample_interval : nil
      end

      def boot?
        target == :boot
      end

      def suite?
        target == :suite
      end
    end

    class << self
      include Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      attr_reader :default_collector

      # Run Vernier and automatically dump
      # a report when the process exits or when the application is booted.
      def run
        collector = profile
        return unless collector

        @locked = true
        @default_collector = collector

        log :info, "Vernier enabled globally: " \
                   "mode – #{config.mode}, target – #{config.target}"

        at_exit { dump(collector, "total") } if config.suite?
      end

      def profile(name = nil)
        if locked?
          log :warn, <<~MSG
            Vernier has been already activated.

            Make sure you do not have the TEST_VERNIER environmental variable set somewhere.
          MSG

          return false
        end

        return false unless init_vernier

        options = {}

        options[:interval] = config.interval if config.interval

        if block_given?
          options[:mode] = config.mode
          options[:out] = build_path(name)
          ::Vernier.trace(**options) { yield }
        else
          collector = ::Vernier::Collector.new(config.mode, **options)
          collector.start

          collector
        end
      end

      def dump(collector, name)
        result = collector.stop

        path = build_path(name)

        File.write(path, ::Vernier::Output::Firefox.new(result).output)

        log :info, "Vernier report generated: #{path}"
      end

      private

      def build_path(name)
        TestProf.artifact_path(
          "vernier-report-#{config.mode}-#{name}.json"
        )
      end

      def locked?
        @locked == true
      end

      def init_vernier
        return @initialized if instance_variable_defined?(:@initialized)
        @locked = false
        @initialized = TestProf.require(
          "vernier",
          <<~MSG
            Please, install 'vernier' first:
               # Gemfile
              gem 'vernier', '>= 0.3.0', require: false
          MSG
        ) { check_vernier_version }
      end

      def check_vernier_version
        if Utils.verify_gem_version("vernier", at_least: "0.3.0")
          true
        else
          log :error, <<~MSG
            Please, upgrade 'vernier' to version >= 0.3.0.
          MSG
          false
        end
      end
    end
  end
end

require "test_prof/vernier/rspec" if TestProf.rspec?

# Hook to run Vernier globally
TestProf.activate("TEST_VERNIER") do
  TestProf::Vernier.run
end
