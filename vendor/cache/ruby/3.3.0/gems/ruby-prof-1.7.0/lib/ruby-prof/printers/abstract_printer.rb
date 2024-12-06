# encoding: utf-8

module RubyProf
  # This is the base class for all Printers. It is never used directly.
  class AbstractPrinter
    # :stopdoc:
    def self.needs_dir?
      false
    end
    # :startdoc:

    # Create a new printer.
    #
    # result should be the output generated from a profiling run
    def initialize(result)
      @result = result
      @output = nil
    end

    # Returns the min_percent of time a method must take to be included in a profiling report
    def min_percent
      @options[:min_percent] || 0
    end

    # Returns the max_percent of time a method can take to be included in a profiling report
    def max_percent
      @options[:max_percent] || 100
    end

    # Returns the method to filter methods by (when using min_percent and max_percent)
    def filter_by
      @options[:filter_by] || :self_time
    end

    # Returns the time format used to show when a profile was run
    def time_format
      '%A, %B %-d at %l:%M:%S %p (%Z)'
    end

    # Returns how profile data should be sorted
    def sort_method
      @options[:sort_method]
    end

    # Prints a report to the provided output.
    #
    # output - Any IO object, including STDOUT or a file.
    # The default value is STDOUT.
    #
    # options - Hash of print options. Note that each printer can
    # define its own set of options.
    #
    #   :min_percent - Number 0 to 100 that specifies the minimum
    #                  %self (the methods self time divided by the
    #                  overall total time) that a method must take
    #                  for it to be printed out in the report.
    #                  Default value is 0.
    #
    #   :sort_method - Specifies method used for sorting method infos.
    #                  Available values are :total_time, :self_time,
    #                  :wait_time, :children_time
    #                  Default value is :total_time
    def print(output = STDOUT, options = {})
      @output = output
      setup_options(options)
      print_threads
    end

    # :nodoc:
    def setup_options(options = {})
      @options = options
    end

    def method_location(method)
      if method.source_file
        "#{method.source_file}:#{method.line}"
      end
    end

    def method_href(thread, method)
      h(method.full_name.gsub(/[><#\.\?=:]/,"_") + "_" + thread.fiber_id.to_s)
    end

    def open_asset(file)
      path = File.join(File.expand_path('../../assets', __FILE__), file)
      File.open(path, 'rb').read
    end

    def print_threads
      @result.threads.each do |thread|
        print_thread(thread)
      end
    end

    def print_thread(thread)
      print_header(thread)
      print_methods(thread)
      print_footer(thread)
    end

    def print_header(thread)
      @output << "Measure Mode: %s\n" % @result.measure_mode_string
      @output << "Thread ID: %d\n" % thread.id
      @output << "Fiber ID: %d\n" % thread.fiber_id unless thread.id == thread.fiber_id
      @output << "Total: %0.6f\n" % thread.total_time
      @output << "Sort by: #{sort_method}\n"
      @output << "\n"
      print_column_headers
    end

    def print_column_headers
    end

    def print_footer(thread)
      @output << <<~EOT

        * recursively called methods

        Columns are:

          %self     - The percentage of time spent in this method, derived from self_time/total_time.
          total     - The time spent in this method and its children.
          self      - The time spent in this method.
          wait      - The amount of time this method waited for other threads.
          child     - The time spent in this method's children.
          calls     - The number of times this method was called.
          name      - The name of the method.
          location  - The location of the method.

        The interpretation of method names is:

          * MyObject#test - An instance method "test" of the class "MyObject"
          * <Object:MyObject>#test - The <> characters indicate a method on a singleton class.

      EOT
    end
  end
end
