# encoding: utf-8

module RubyProf
  # Generates flat[link:files/examples/flat_txt.html] profile reports as text.
  # To use the flat printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::FlatPrinter.new(result)
  #   printer.print(STDOUT, {})
  #
  class FlatPrinter < AbstractPrinter
    # Override for this printer to sort by self time by default
    def sort_method
      @options[:sort_method] || :self_time
    end

    private

    def print_column_headers
      @output << " %self      total      self      wait     child     calls  name                           location\n"
    end

    def print_methods(thread)
      total_time = thread.total_time
      methods = thread.methods.sort_by(&sort_method).reverse

      sum = 0
      methods.each do |method|
        percent = (method.send(filter_by) / total_time) * 100
        next if percent < min_percent
        next if percent > max_percent

        sum += method.self_time
        #self_time_called = method.called > 0 ? method.self_time/method.called : 0
        #total_time_called = method.called > 0? method.total_time/method.called : 0

        @output << "%6.2f  %9.3f %9.3f %9.3f %9.3f %8d  %s%-30s %s\n" % [
                      method.self_time / total_time * 100, # %self
                      method.total_time,                   # total
                      method.self_time,                    # self
                      method.wait_time,                    # wait
                      method.children_time,                # children
                      method.called,                       # calls
                      method.recursive? ? "*" : " ",       # cycle
                      method.full_name,                    # method_name]
                      method_location(method)]             # location]
      end
    end
  end
end