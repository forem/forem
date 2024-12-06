# encoding: utf-8

module RubyProf
  # Generates graph[link:files/examples/graph_txt.html] profile reports as text.
  # To use the graph printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::GraphPrinter.new(result)
  #   printer.print(STDOUT, {})
  #
  # The constructor takes two arguments. See the README

  class GraphPrinter < AbstractPrinter
    PERCENTAGE_WIDTH = 8
    TIME_WIDTH = 11
    CALL_WIDTH = 17

    private

    def sort_method
      @options[:sort_method] || :total_time
    end

    def print_header(thread)
      @output << "Measure Mode: %s\n" % @result.measure_mode_string
      @output << "Thread ID: #{thread.id}\n"
      @output << "Fiber ID: #{thread.fiber_id}\n"
      @output << "Total Time: #{thread.total_time}\n"
      @output << "Sort by: #{sort_method}\n"
      @output << "\n"

      # 1 is for % sign
      @output << sprintf("%#{PERCENTAGE_WIDTH}s", "%total")
      @output << sprintf("%#{PERCENTAGE_WIDTH}s", "%self")
      @output << sprintf("%#{TIME_WIDTH}s", "total")
      @output << sprintf("%#{TIME_WIDTH}s", "self")
      @output << sprintf("%#{TIME_WIDTH}s", "wait")
      @output << sprintf("%#{TIME_WIDTH}s", "child")
      @output << sprintf("%#{CALL_WIDTH}s", "calls")
      @output << "     name"
      @output << "                          location"
      @output << "\n"
    end

    def print_methods(thread)
      total_time = thread.total_time
      # Sort methods from longest to shortest total time
      methods = thread.methods.sort_by(&sort_method)

      # Print each method in total time order
      methods.reverse_each do |method|
        total_percentage = (method.total_time/total_time) * 100
        next if total_percentage < min_percent

        self_percentage = (method.self_time/total_time) * 100

        @output << "-" * 150 << "\n"
        print_parents(thread, method)

        # 1 is for % sign
        @output << sprintf("%#{PERCENTAGE_WIDTH-1}.2f%%", total_percentage)
        @output << sprintf("%#{PERCENTAGE_WIDTH-1}.2f%%", self_percentage)
        @output << sprintf("%#{TIME_WIDTH}.3f", method.total_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", method.self_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", method.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", method.children_time)
        @output << sprintf("%#{CALL_WIDTH}i", method.called)
        @output << sprintf("    %s",  method.recursive? ? "*" : " ")
        @output << sprintf("%-30s", method.full_name)
        @output << sprintf(" %s", method_location(method))
        @output << "\n"

        print_children(method)
      end
    end

    def print_parents(thread, method)
      method.call_trees.callers.sort_by(&:total_time).each do |caller|
        @output << " " * 2 * PERCENTAGE_WIDTH
        @output << sprintf("%#{TIME_WIDTH}.3f", caller.total_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", caller.self_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", caller.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", caller.children_time)

        call_called = "#{caller.called}/#{method.called}"
        @output << sprintf("%#{CALL_WIDTH}s", call_called)
        @output << sprintf("     %s", caller.parent.target.full_name)
        @output << "\n"
      end
    end

    def print_children(method)
      method.call_trees.callees.sort_by(&:total_time).reverse.each do |child|
        # Get children method

        @output << " " * 2 * PERCENTAGE_WIDTH

        @output << sprintf("%#{TIME_WIDTH}.3f", child.total_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", child.self_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", child.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.3f", child.children_time)

        call_called = "#{child.called}/#{child.target.called}"
        @output << sprintf("%#{CALL_WIDTH}s", call_called)
        @output << sprintf("     %s", child.target.full_name)
        @output << "\n"
      end
    end
  end
end
