# encoding: utf-8

module RubyProf
  # The MethodInfo class is used to track information about each method that is profiled.
  # You cannot create a MethodInfo object directly, they are generated while running a profile.
  class MethodInfo
    include Comparable

    # Returns the full name of a class. The interpretation of method names is:
    #
    # * MyObject#test - An method defined in a class
    # * <Class:MyObject>#test - A method defined in a singleton class.
    # * <Module:MyObject>#test - A method defined in a singleton module.
    # * <Object:MyObject>#test - A method defined in a singleton object.
    def full_name
      decorated_class_name = case self.klass_flags
                             when 0x2
                               "<Class::#{klass_name}>"
                             when 0x4
                               "<Module::#{klass_name}>"
                             when 0x8
                               "<Object::#{klass_name}>"
                             else
                               klass_name
                             end

      "#{decorated_class_name}##{method_name}"
    end

    # The number of times this method was called
    def called
      self.measurement.called
    end

    # The total time this method took - includes self time + wait time + child time
    def total_time
      self.measurement.total_time
    end

    # The time this method took to execute
    def self_time
      self.measurement.self_time
    end

    # The time this method waited for other fibers/threads to execute
    def wait_time
      self.measurement.wait_time
    end

    # The time this method's children took to execute
    def children_time
      self.total_time - self.self_time - self.wait_time
    end

    def eql?(other)
      self.hash == other.hash
    end

    def ==(other)
      self.eql?(other)
    end

    def <=>(other)
      sort_delta = 0.0001

      if other.nil?
        -1
      elsif self.full_name == other.full_name
        0
      elsif self.total_time < other.total_time && (self.total_time - other.total_time).abs > sort_delta
        -1
      elsif self.total_time > other.total_time && (self.total_time - other.total_time).abs > sort_delta
        1
      elsif self.call_trees.min_depth < other.call_trees.min_depth
        1
      elsif self.call_trees.min_depth > other.call_trees.min_depth
        -1
      else
        self.full_name <=> other.full_name
      end
    end

    def to_s
      "#{self.full_name} (c: #{self.called}, tt: #{self.total_time}, st: #{self.self_time}, wt: #{wait_time}, ct: #{self.children_time})"
    end
  end
end
