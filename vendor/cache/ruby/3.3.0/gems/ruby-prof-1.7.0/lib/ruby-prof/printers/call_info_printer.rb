# encoding: utf-8

module RubyProf
  # Prints out the call graph based on CallTree instances. This
  # is mainly for debugging purposes as it provides access into
  # into RubyProf's internals.
  #
  # To use the printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::CallInfoPrinter.new(result)
  #   printer.print(STDOUT)
  class CallInfoPrinter < AbstractPrinter
    TIME_WIDTH = 0

    private

    def print_header(thread)
      @output << "----------------------------------------------------\n"
      @output << "Thread ID: #{thread.id}\n"
      @output << "Fiber ID: #{thread.fiber_id}\n"
      @output << "Total Time: #{thread.total_time}\n"
      @output << "Sort by: #{sort_method}\n"
      @output << "\n"
    end

    def print_methods(thread)
      visitor = CallTreeVisitor.new(thread.call_tree)

      visitor.visit do |call_tree, event|
        if event == :enter
          @output << "  " * call_tree.depth
          @output << call_tree.target.full_name
          @output << " ("
          @output << "tt:#{sprintf("%#{TIME_WIDTH}.2f", call_tree.total_time)}, "
          @output << "st:#{sprintf("%#{TIME_WIDTH}.2f", call_tree.self_time)}, "
          @output << "wt:#{sprintf("%#{TIME_WIDTH}.2f", call_tree.wait_time)}, "
          @output << "ct:#{sprintf("%#{TIME_WIDTH}.2f", call_tree.children_time)}, "
          @output << "call:#{call_tree.called}, "
          @output << ")"
          @output << "\n"
        end
      end
    end

    def print_footer(thread)
      @output << "\n" << "\n"
    end
  end
end
