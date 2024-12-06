module RubyProf
  # The Measurement class is a helper class used by RubyProf::MethodInfo to store information about the method.
  # You cannot create a CallTree object directly, they are generated while running a profile.
  class Measurement
    def children_time
      self.total_time - self.self_time - self.wait_time
    end

    def to_s
      "c: #{called}, tt: #{total_time}, st: #{self_time}"
    end

    def inspect
      super + "(#{self.to_s})"
    end
  end
end
