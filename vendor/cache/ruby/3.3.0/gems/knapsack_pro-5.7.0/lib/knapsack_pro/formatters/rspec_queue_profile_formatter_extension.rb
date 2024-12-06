# frozen_string_literal: true

RSpec::Support.require_rspec_core('formatters/profile_formatter')

module KnapsackPro
  module Formatters
    module RSpecQueueProfileFormatterExtension
      def self.print_summary
        return unless KnapsackPro::Config::Env.modify_default_rspec_formatters?
        ::RSpec::Core::Formatters::ProfileFormatter.print_profile_summary
      end

      def initialize(output)
        @output = output
        self.class.registered_output = output
      end

      def dump_profile(profile)
        self.class.most_recent_profile = profile
      end
    end
  end
end

if KnapsackPro::Config::Env.modify_default_rspec_formatters?
  class RSpec::Core::Formatters::ProfileFormatter
    prepend KnapsackPro::Formatters::RSpecQueueProfileFormatterExtension

    def self.registered_output=(output)
      @registered_output = {
        ENV['KNAPSACK_PRO_QUEUE_ID'] => output
      }
    end

    def self.registered_output
      @registered_output ||= {}
      @registered_output[ENV['KNAPSACK_PRO_QUEUE_ID']]
    end

    def self.most_recent_profile=(profile)
      @most_recent_profile = {
        ENV['KNAPSACK_PRO_QUEUE_ID'] => profile
      }
    end

    def self.most_recent_profile
      @most_recent_profile ||= {}
      @most_recent_profile[ENV['KNAPSACK_PRO_QUEUE_ID']] || []
    end

    def self.print_profile_summary
      return unless registered_output
      profile_formatter = new(registered_output)
      profile_formatter.send(:dump_profile_slowest_examples,  most_recent_profile)
      profile_formatter.send(:dump_profile_slowest_example_groups, most_recent_profile)
    end
  end
end
