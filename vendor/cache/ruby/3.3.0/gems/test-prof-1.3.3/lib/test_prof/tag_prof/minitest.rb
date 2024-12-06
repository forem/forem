# frozen_string_literal: true

module Minitest
  module TestProf
    class TagProfReporter < BaseReporter # :nodoc:
      attr_reader :results

      def initialize(io = $stdout, _options = {})
        super
        @results = ::TestProf::TagProf::Result.new("type")

        if event_prof_activated?
          require "test_prof/event_prof"
          @current_group_id = nil
          @events_profiler = configure_profiler
          @results = ::TestProf::TagProf::Result.new("type", @events_profiler.events)
        end
      end

      def prerecord(group, example)
        return unless event_prof_activated?

        # enable event profiling
        @events_profiler.group_started(true)
      end

      def record(result)
        results.track(main_folder_path(result), time: result.time, events: fetch_events_data)
        @events_profiler.group_started(nil) if event_prof_activated? # reset and disable event profilers
      end

      def report
        printer = (ENV["TAG_PROF_FORMAT"] == "html") ? ::TestProf::TagProf::Printers::HTML : ::TestProf::TagProf::Printers::Simple
        printer.dump(results)
      end

      private

      def main_folder_path(result)
        return :__unknown__ if absolute_path_from(result).nil?

        absolute_path_from(result)
      end

      def absolute_path_from(result)
        absolute_path = File.expand_path(result.source_location.first)
        absolute_path.slice(/(?<=(?:spec|test)\/)\w*/)
      end

      def configure_profiler
        ::TestProf::EventProf::CustomEvents.activate_all(tag_prof_event)
        ::TestProf::EventProf.build(tag_prof_event)
      end

      def event_prof_activated?
        return false if tag_prof_event.nil?

        !tag_prof_event.empty?
      end

      def tag_prof_event
        ENV["TAG_PROF_EVENT"]
      end

      def fetch_events_data
        return {} unless @events_profiler

        @events_profiler.profilers.map do |profiler|
          [profiler.event, profiler.time || 0.0]
        end.to_h
      end
    end
  end
end
