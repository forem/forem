# frozen_string_literal: true

require "test_prof/memory_prof/tracker/linked_list"
require "test_prof/memory_prof/tracker/rss_tool"

module TestProf
  module MemoryProf
    # Tracker is responsible for tracking memory usage and determining
    # the top n examples and groups. There are two types of trackers:
    # AllocTracker and RssTracker.
    #
    # A tracker consists of four main parts:
    #  * list - a linked list that is being used to track memmory for individual groups/examples.
    #    list is an instance of LinkedList (for more info see tracker/linked_list.rb)
    #  * examples – the top n examples, an instance of Utils::SizedOrderedSet.
    #  * groups – the top n groups, an instance of Utils::SizedOrderedSet.
    #  * track - a method that fetches the amount of memory in use at a certain point.
    class Tracker
      attr_reader :top_count, :examples, :groups, :total_memory, :list

      def initialize(top_count)
        raise "Your Ruby Engine or OS is not supported" unless supported?

        @top_count = top_count

        @examples = Utils::SizedOrderedSet.new(top_count, sort_by: :memory)
        @groups = Utils::SizedOrderedSet.new(top_count, sort_by: :memory)
      end

      def start
        @list = LinkedList.new(track)
      end

      def finish
        node = list.remove_node(:total, track)
        @total_memory = node.total_memory
      end

      def example_started(id, example = id)
        list.add_node(id, example, track)
      end

      def example_finished(id)
        node = list.remove_node(id, track)
        return unless node

        examples << {**node.item, memory: node.total_memory}
      end

      def group_started(id, group = id)
        list.add_node(id, group, track)
      end

      def group_finished(id)
        node = list.remove_node(id, track)
        return unless node

        groups << {**node.item, memory: node.hooks_memory}
      end
    end

    class AllocTracker < Tracker
      def track
        GC.stat[:total_allocated_objects]
      end

      def supported?
        RUBY_ENGINE != "jruby"
      end
    end

    class RssTracker < Tracker
      def initialize(top_count)
        @rss_tool = RssTool.tool

        super
      end

      def track
        @rss_tool.track
      end

      def supported?
        !!@rss_tool
      end
    end
  end
end
