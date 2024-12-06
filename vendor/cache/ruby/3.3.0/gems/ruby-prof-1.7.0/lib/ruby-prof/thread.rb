module RubyProf
  class Thread
    # Returns the total time this thread was executed.
    def total_time
      self.call_tree.total_time
    end

    # Returns the amount of time this thread waited while other thread executed.
    def wait_time
      # wait_time, like self:time, is always method local
      # thus we need to sum over all methods and call infos
      self.methods.inject(0) do |sum, method_info|
        method_info.callers.each do |call_tree|
          sum += call_tree.wait_time
        end
        sum
      end
    end
  end
end
