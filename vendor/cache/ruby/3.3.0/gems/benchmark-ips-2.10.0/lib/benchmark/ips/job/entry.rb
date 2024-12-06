module Benchmark
  module IPS
    # Benchmark jobs.
    class Job
      # Entries in Benchmark Jobs.
      class Entry
        # Instantiate the Benchmark::IPS::Job::Entry.
        # @param label [#to_s] Label of Benchmarked code.
        # @param action [String, Proc] Code to be benchmarked.
        # @raise [ArgumentError] Raises when action is not String or not responding to +call+.
        def initialize(label, action)
          @label = label

          # We define #call_times on the singleton class of each Entry instance.
          # That way, there is no polymorphism for `@action.call` inside #call_times.

          if action.kind_of? String
            compile_string action
            @action = self
          else
            unless action.respond_to? :call
              raise ArgumentError, "invalid action, must respond to #call"
            end

            @action = action

            if action.respond_to? :arity and action.arity > 0
              compile_block_with_manual_loop
            else
              compile_block
            end
          end
        end

        # The label of benchmarking action.
        # @return [#to_s] Label of action.
        attr_reader :label

        # The benchmarking action.
        # @return [String, Proc] Code to be called, could be String / Proc.
        attr_reader :action

        # Call action by given times.
        # @param times [Integer] Times to call +@action+.
        # @return [Integer] Number of times the +@action+ has been called.
        def call_times(times)
          raise '#call_times should be redefined per Benchmark::IPS::Job::Entry instance'
        end

        def compile_block
          m = (class << self; self; end)
          code = <<-CODE
            def call_times(times)
              act = @action

              i = 0
              while i < times
                act.call
                i += 1
              end
            end
          CODE
          m.class_eval code
        end

        def compile_block_with_manual_loop
          m = (class << self; self; end)
          code = <<-CODE
            def call_times(times)
              @action.call(times)
            end
          CODE
          m.class_eval code
        end

        # Compile code into +call_times+ method.
        # @param str [String] Code to be compiled.
        # @return [Symbol] :call_times.
        def compile_string(str)
          m = (class << self; self; end)
          code = <<-CODE
            def call_times(__total);
              __i = 0
              while __i < __total
                #{str};
                __i += 1
              end
            end
          CODE
          m.class_eval code
        end
      end
    end
  end
end
