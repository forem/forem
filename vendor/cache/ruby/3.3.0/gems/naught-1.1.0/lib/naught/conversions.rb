module Naught
  module Conversions
    def self.included(null_class)
      unless class_variable_defined?(:@@included) && @@included
        @@null_class = null_class
        @@null_equivs = null_class::NULL_EQUIVS
        @@included = true
      end
      super
    end

    def Null(object = :nothing_passed)
      case object
      when NullObjectTag
        object
      when :nothing_passed, *@@null_equivs
        @@null_class.get(:caller => caller(1))
      else
        fail(ArgumentError.new("#{object.inspect} is not null!"))
      end
    end

    def Maybe(object = nil)
      object = yield if block_given?
      case object
      when NullObjectTag
        object
      when *@@null_equivs
        @@null_class.get(:caller => caller(1))
      else
        object
      end
    end

    def Just(object = nil)
      object = yield if block_given?
      case object
      when NullObjectTag, *@@null_equivs
        fail(ArgumentError.new("Null value: #{object.inspect}"))
      else
        object
      end
    end

    def Actual(object = nil)
      object = yield if block_given?
      case object
      when NullObjectTag
        nil
      else
        object
      end
    end
  end
end
