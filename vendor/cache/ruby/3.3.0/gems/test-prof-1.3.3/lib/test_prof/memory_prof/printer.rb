# frozen_string_literal: true

require "test_prof/memory_prof/printer/number_to_human"
require "test_prof/ext/string_truncate"

module TestProf
  module MemoryProf
    class Printer
      include Logging
      using StringTruncate

      def initialize(tracker)
        @tracker = tracker
      end

      def print
        messages = [
          "MemoryProf results\n\n",
          print_total,
          print_block("groups", tracker.groups),
          print_block("examples", tracker.examples)
        ]

        log :info, messages.join
      end

      private

      attr_reader :tracker

      def print_block(name, items)
        return if items.empty?

        <<~GROUP
          Top #{tracker.top_count} #{name} (by #{mode}):

          #{print_items(items)}
        GROUP
      end

      def print_items(items)
        messages =
          items.map do |item|
            <<~ITEM
              #{item[:name].truncate(30)} (#{item[:location]}) – +#{memory_amount(item)} (#{memory_percentage(item)}%)
            ITEM
          end

        messages.join
      end

      def memory_percentage(item)
        return 0 if tracker.total_memory.zero? || item[:memory].zero?

        (100.0 * item[:memory] / tracker.total_memory).round(2)
      end

      def number_to_human(value)
        NumberToHuman.convert(value)
      end
    end

    class AllocPrinter < Printer
      private

      def mode
        "allocations"
      end

      def print_total
        "Total allocations: #{tracker.total_memory}\n\n"
      end

      def memory_amount(item)
        item[:memory]
      end
    end

    class RssPrinter < Printer
      private

      def mode
        "RSS"
      end

      def print_total
        "Final RSS: #{number_to_human(tracker.total_memory)}\n\n"
      end

      def memory_amount(item)
        number_to_human(item[:memory])
      end
    end
  end
end
