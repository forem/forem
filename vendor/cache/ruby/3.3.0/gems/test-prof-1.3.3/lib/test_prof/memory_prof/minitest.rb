# frozen_string_literal: true

require "minitest/base_reporter"

module Minitest
  module TestProf
    class MemoryProfReporter < BaseReporter # :nodoc:
      attr_reader :tracker, :printer, :current_example

      def initialize(io = $stdout, options = {})
        super

        configure_profiler(options)

        @tracker = ::TestProf::MemoryProf.tracker
        @printer = ::TestProf::MemoryProf.printer(tracker)

        @current_example = nil
      end

      def prerecord(group, example)
        set_current_example(group, example)
        tracker.example_started(current_example)
      end

      def record(example)
        tracker.example_finished(current_example)
      end

      def start
        tracker.start
      end

      def report
        tracker.finish
        printer.print
      end

      private

      def set_current_example(group, example)
        @current_example = {
          name: example.gsub(/^test_(?:\d+_)?/, ""),
          location: location_with_line_number(group, example)
        }
      end

      def configure_profiler(options)
        ::TestProf::MemoryProf.configure do |config|
          config.mode = options[:mem_prof_mode]
          config.top_count = options[:mem_prof_top_count] if options[:mem_prof_top_count]
        end
      end
    end
  end
end
