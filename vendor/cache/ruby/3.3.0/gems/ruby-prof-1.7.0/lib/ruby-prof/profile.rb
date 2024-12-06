# encoding: utf-8

require 'ruby-prof/exclude_common_methods'

module RubyProf
  class Profile
    def measure_mode_string
      case self.measure_mode
        when WALL_TIME
          "wall_time"
        when PROCESS_TIME
          "process_time"
        when ALLOCATIONS
          "allocations"
        when MEMORY
          "memory"
      end
    end

    # Hides methods that, when represented as a call graph, have
    # extremely large in and out degrees and make navigation impossible.
    def exclude_common_methods!
      ExcludeCommonMethods.apply!(self)
    end

    def exclude_methods!(mod, *method_names)
      [method_names].flatten.each do |method_name|
        exclude_method!(mod, method_name)
      end
    end

    def exclude_singleton_methods!(mod, *method_names)
      exclude_methods!(mod.singleton_class, *method_names)
    end

    # call-seq:
    # merge! -> self
    #
    # Merges RubyProf threads whose root call_trees reference the same target method. This is useful
    # when profiling code that uses a main thread/fiber to distribute work to multiple workers.
    # If there are tens or hundreds of workers, viewing results per worker thread/fiber can be
    # overwhelming. Using +merge!+ will combine the worker times together into one result.
    #
    # Note the reported time will be much greater than the actual wall time. For example, if there
    # are 10 workers that each run for 5 seconds, merged results will show one thread that
    # ran for 50 seconds.
    #
    def merge!
      # First group threads by their root call tree target (method). If the methods are
      # different than there is nothing to merge
      grouped = threads.group_by do |thread|
        thread.call_tree.target
      end

      # For each target, get the first thread. Then loop over the remaining threads,
      # and merge them into the first one and ten delete them. So we will be left with
      # one thread per target.
      grouped.each do |target, threads|
        thread = threads.shift
        threads.each do |other_thread|
          thread.merge!(other_thread)
          remove_thread(other_thread)
        end
        thread
      end

      self
    end
  end
end
