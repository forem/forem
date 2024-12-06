# frozen_string_literal: true

module TestProf
  module MemoryProf
    class Tracker
      # LinkedList is a linked list that track memory usage for individual examples/groups.
      # A list node (`LinkedListNode`) represents an example/group and its memory usage info:
      #
      # * memory_at_start - the amount of memory at the start of an example/group
      # * memory_at_finish - the amount of memory at the end of an example/group
      # * nested_memory - the amount of memory allocated by examples/groups defined inside a group
      # * previous - a link to the previous node
      #
      # Each node has a link to its previous node, and the head node points to the current example/group.
      # If we picture a linked list as a tree with root being the top level group and leaves being
      # current examples/groups, then the head node will always point to a leaf in that tree.
      #
      # For example, if we have the following spec:
      #
      #   describe Question do
      #     decribe "#publish" do
      #       context "when not published" do
      #         it "makes the question visible" do
      #           ...
      #         end
      #       end
      #     end
      #   end
      #
      # At the moment when rspec is executing the example, the list has the following structure
      # (^ denotes the head node):
      #
      #    ^"makes the question visible" ->  "when not published" -> "#publish" -> Question
      #
      # LinkedList supports two method for working with it:
      #
      #  * add_node – adds a node to the beginig of the list. At this point an example or group
      #    has started and we track how much memory has already been used.
      #  * remove_node – removes and returns the head node from the list. It means that the node
      #    example/group has finished and it is time to calculate its memory usage.
      #
      # When we remove a node we add its total_memory to the previous node.nested_memory, thus
      # gradually tracking the amount of memory used by nested examples inside a group.
      #
      # In the example above, after we remove the node "makes the question visible", we add its total
      # memory usage to nested_memory of the "when not published" node. If the "when not published"
      # group contains other examples or sub-groups, their total_memory will also be added to
      # "when not published" nested_memory. So when the group finishes we will have the total amount
      # of memory used by its nested examples/groups, and thus we will be able to calculate the memory
      # used by hooks and other code inside a group by subtracting nested_memory from total_memory.
      class LinkedList
        attr_reader :head

        def initialize(memory_at_start)
          add_node(:total, :total, memory_at_start)
        end

        def add_node(id, item, memory_at_start)
          @head = LinkedListNode.new(
            id: id,
            item: item,
            previous: head,
            memory_at_start: memory_at_start
          )
        end

        def remove_node(id, memory_at_finish)
          return if head.id != id
          head.finish(memory_at_finish)

          current = head
          @head = head.previous

          current
        end
      end

      class LinkedListNode
        attr_reader :id, :item, :previous, :memory_at_start, :memory_at_finish, :nested_memory

        def initialize(id:, item:, memory_at_start:, previous:)
          @id = id
          @item = item
          @previous = previous

          @memory_at_start = memory_at_start || 0
          @memory_at_finish = nil
          @nested_memory = 0
        end

        def total_memory
          return 0 if memory_at_finish.nil?
          # It seems that on Windows Minitest may release a lot of memory to
          # the OS when it finishes and executes #report, leading to memory_at_finish
          # being less than memory_at_start. In this case we return nested_memory
          # which does not account for the memory used in `after` hooks, but it
          # is better than nothing.
          return nested_memory if memory_at_start > memory_at_finish

          memory_at_finish - memory_at_start
        end

        def hooks_memory
          total_memory - nested_memory
        end

        def finish(memory_at_finish)
          @memory_at_finish = memory_at_finish

          previous&.add_nested(self)
        end

        protected

        def add_nested(node)
          @nested_memory += node.total_memory
        end
      end
    end
  end
end
